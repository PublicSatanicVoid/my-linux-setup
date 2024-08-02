#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/ptrace.h>
#include <sys/user.h>
#include <sys/syscall.h>
#include <sys/stat.h>
#include <sys/reg.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <libgen.h>

#define TRACE_OK 0
#define TRACE_ERROR_NONFATAL 1
#define TRACE_ERROR_FATAL 2

#define TRACE_LINKED_LIST 0
#define TRACE_ALLOWED_PATHS 0
#define TRACE_CHILD_PIDS 0
#define TRACE_OPENS 0
#define SANDBOX_ENABLED 1
#define ALLOW_TMP 1
#define ALLOW_TMP_OTHER_USER 0
#define ALLOW_HOME 0
#define ALLOW_HOME_OTHER_USER 0

/************
 * TODOs
 *  - Get or save (and update on set*uid) real UID of process, and use that when
 *  evaluating file ownership in context of given process
 *
 ************/

// #define MIN(x,y) ((x)<(y)?(x):(y))

// Some syscalls aren't defined in all library versions we want to support

#ifndef SYS_pwritev2
#   define SYS_pwritev2 328
#endif

#ifndef SYS_clone3
#   define SYS_clone3 435
#endif

#ifndef SYS_openat2
#   define SYS_openat2 437
struct open_how {
    int flags;
    mode_t mode;
    int resolve;
};
#else
#   include <linux/openat2.h>
#endif

#ifndef SYS_fchmodat2
#   define SYS_fchmodat2 452
#endif


// Data structure for tracking info about a descendant process.

struct process_state {
    pid_t pid;
    int changed_stdout_fd : 1;
    int changed_stderr_fd : 1;

    struct process_state *left;
    struct process_state *right;
};

static struct process_state *process_state_start = NULL;

inline void get_user_homedir(uid_t uid, char* homedir, size_t maxsize) {
    struct passwd *pwd = getpwuid(uid);
    strncpy(homedir, pwd->pw_dir, maxsize - 1);
    homedir[PATH_MAX-1] = '\0';
}

inline uid_t path_owner(char* path) {
    struct stat buf;
    stat(path, &buf);
    return buf.st_uid;
}

int is_allowed_path(char* path) {
    char real_desired_path[PATH_MAX];
    realpath(path, real_desired_path);

    if (!strcmp(real_desired_path, "/dev/tty")) {
        if (TRACE_ALLOWED_PATHS) printf("trace: allowing (tty): %s\n", path);
        return 1;
    }
    if (strstr(real_desired_path, "/dev/pts")) {
        if (TRACE_ALLOWED_PATHS) printf("trace: allowing (pts): %s\n", path);
        return 1;
    }
    if (ALLOW_TMP && (
            strstr(real_desired_path, "/tmp/")
            || strstr(real_desired_path, "/var/tmp/")
    )) {
        if (!ALLOW_TMP_OTHER_USER && path_owner(real_desired_path) != getuid()) {
            return 0;
        }
        if (TRACE_ALLOWED_PATHS) printf("trace: allowing (tmp): %s\n", path);
        return 1;
    }
    if (ALLOW_HOME) {
        char homedir[PATH_MAX];
        get_user_homedir(getuid(), homedir, PATH_MAX);
        char real_homedir[PATH_MAX];
        realpath(homedir, real_homedir);  // home dir could be a symlink
        char real_homedir_suffix[PATH_MAX+1];
        snprintf(real_homedir_suffix, PATH_MAX+1, "%s/", real_homedir);
        if (strstr(real_desired_path, real_homedir)) {
            if (!ALLOW_HOME_OTHER_USER && path_owner(real_desired_path) != getuid()) {
                return 0;
            }
            if (TRACE_ALLOWED_PATHS) printf("trace: allowing (home): %s\n", path);
            return 1;
        }
    }

    return 0;
}

void init_process_state(struct process_state *state, pid_t pid) {
    state->pid = pid;
    state->changed_stdout_fd = 0;
    state->changed_stderr_fd = 0;
    state->left = NULL;
    state->right = NULL;
}

void free_process_state(struct process_state *state) {

    struct process_state *L = state->left;
    struct process_state *R = state->right;

    if (L == NULL && R == NULL) {}
    else if (L == NULL) {
        R->left = NULL;
    }
    else if (R == NULL) {
        L->right = NULL;
    }
    else {
        L->right = R;
        R->left = L;
    }

    if (process_state_start == state) {
        if (state->left != NULL) 
            process_state_start = state->left;
        else
            process_state_start = state->right;
    }

    free(state);
}


// Returns pointer to `pid`'s process state, inserting one if it does not yet exist.
struct process_state *get_process_state(pid_t pid) {
    struct process_state *buf = process_state_start;
    if (buf == NULL) {
        process_state_start = malloc(sizeof (struct process_state));
        init_process_state(process_state_start, pid);
        return process_state_start;
    }
    while (buf != NULL) {

        if (buf->left == NULL && buf->pid > pid) {
            // Insert new at very left
            buf->left = malloc(sizeof (struct process_state));
            init_process_state(buf->left, pid);
            buf->left->right = buf;
            return buf->left;
        }
        if (buf->left->pid < pid && buf->pid > pid) {
            // Insert between buf->left and buf
            struct process_state *entry = malloc(sizeof (struct process_state));
            init_process_state(entry, pid);
            entry->left = buf->left;
            entry->right = buf;
            buf->left->right = entry;
            buf->left = entry;
            return entry;
        }
        if (buf->pid == pid) {
            return buf;
        }
        if (buf->right == NULL && pid > buf->pid) {
            // Insert new at very right
            buf->right = malloc(sizeof (struct process_state));
            init_process_state(buf->right, pid);
            buf->right->left = buf;
            return buf->right;
        }
        if (buf->pid < pid && buf->right->pid > pid) {
            // Insert between buf and buf->right
            struct process_state *entry = malloc(sizeof (struct process_state));
            init_process_state(entry, pid);
            entry->left = buf;
            entry->right = buf->right;
            buf->right->left = entry;
            buf->right = entry;
            return entry;
        }
        if (pid < buf->pid) {
            buf = buf->left;
        }
        else if (pid > buf->pid) {
            buf = buf->right;
        }
        else {
            printf("logic error, you suck\n");
        }
    }

    printf("logic error 2, you suck\n");

    
    return NULL;
}

inline void mark_changed_stdout_fd(pid_t pid) {
    get_process_state(pid)->changed_stdout_fd = 1;
}

inline void mark_changed_stderr_fd(pid_t pid) {
    get_process_state(pid)->changed_stderr_fd = 1;
}

inline int is_stdout_changed(pid_t pid) {
    return get_process_state(pid)->changed_stdout_fd;
}

inline int is_stderr_changed(pid_t pid) {
    return get_process_state(pid)->changed_stderr_fd;
}

/* Changes the current syscall of process `pid` to SYS_getpid, then waits for it to
 * finish and sets the return value to `retval`.
 *
 * To `pid`, it appears the current syscall returned `retval`, but in reality, the
 * syscall was never executed.
 *
 * `regs` argument may be NULL. If not NULL, must be the current register state of
 * `pid`.
 */
int spoof_syscall(pid_t pid, long retval, struct user_regs_struct *regs) {
    int status;

    if (regs == NULL) {
        status = ptrace(PTRACE_GETREGS, pid, 0, regs);
        if (status) {
            perror("ptrace(getregs) during spoof_syscall()");
            return -1;
        }
    }

    // Replace current syscall with getpid
    regs->orig_rax = SYS_getpid;
    ptrace(PTRACE_SETREGS, pid, NULL, regs);

    // Wait for getpid to finish
    ptrace(PTRACE_SYSCALL, pid, 0, 0);
    waitpid(pid, &status, 0);
    if (WIFEXITED(status)) {
        printf("Child %d exited during spoofing of syscall\n", pid);
        return TRACE_ERROR_NONFATAL;
    }

    struct user_regs_struct new_regs;
    ptrace(PTRACE_GETREGS, pid, NULL, &new_regs);
    if (new_regs.orig_rax != SYS_getpid) {
        printf("Child %d skipped over exit of dummy syscall into syscall %llu\n",
               pid, new_regs.orig_rax);
    }

    // Change the return value to `retval`
    new_regs.rax = retval;
    ptrace(PTRACE_SETREGS, pid, NULL, &new_regs);

    //printf("Spoofed syscall and returned value %ld\n", retval);

    return TRACE_OK;
}

int trace_syscall(pid_t pid) {
    //struct process_state *state = get_process_state(pid);
    //if (state->pid != pid) {
    //    printf("Wow, you're really bad at this!\n");
    //    return TRACE_ERROR_FATAL;
    //}
    //printf("DEBUG: pid %d vs %d, state=%p\n", pid, state->pid, state);

    //return TRACE_OK;

    int status;
    struct user_regs_struct regs;
    status = ptrace(PTRACE_GETREGS, pid, 0, &regs);
    if (status) {
        perror("ptrace(getregs) during trace_syscall()");
        return TRACE_ERROR_NONFATAL;
    }
    long syscall = regs.orig_rax;


    //printf("Pid %d: Syscall %ld\n", pid, syscall);

    if (syscall == SYS_fork || syscall == SYS_vfork || syscall == SYS_clone
            || syscall == SYS_clone3) {
        ptrace(PTRACE_SYSCALL, pid, 0, 0);
        waitpid(pid, &status, 0); // TODO error handling
        struct user_regs_struct fork_done_regs;
        status = ptrace(PTRACE_GETREGS, pid, 0, &fork_done_regs);
        if (status) {
            perror("ptrace(getregs) during handling of fork()");
            return TRACE_ERROR_FATAL;
        }
        
        int fork_child = fork_done_regs.rax;
        if (fork_child < 0) {
            // Their fork failed, that's fine - ignore it
            return TRACE_OK;
        }
        
        if (TRACE_CHILD_PIDS)
            printf("<NEW: %d>\n", fork_child);
        ptrace(PTRACE_ATTACH, fork_child, 0, 0);

    }

    else if (syscall == SYS_write || syscall == SYS_pwrite64 || syscall == SYS_writev
            || syscall == SYS_pwritev || syscall == SYS_pwritev2
            || syscall == SYS_tee) {

        return TRACE_OK;  // Try catching at the open() level instead

        int fd = (syscall == SYS_tee ? regs.rsi : regs.rdi);
        long count = regs.rdx;

        int spoof = 1;
        if (fd == STDOUT_FILENO) spoof = is_stdout_changed(pid);
        else if (fd == STDERR_FILENO) spoof = is_stderr_changed(pid);

        if (SANDBOX_ENABLED && spoof)
            return spoof_syscall(pid, count, &regs);
    }
    else if (syscall == SYS_dup2 || syscall == SYS_dup3) {
        int newfd = regs.rsi;
        if (newfd == STDOUT_FILENO) mark_changed_stdout_fd(pid);
        else if (newfd == STDERR_FILENO) mark_changed_stderr_fd(pid);
    }
    else if (syscall == SYS_close) {
        int fd = regs.rdi;
        if (fd == STDOUT_FILENO) mark_changed_stdout_fd(pid);
        else if (fd == STDERR_FILENO) mark_changed_stderr_fd(pid);
    }

    else if (syscall == SYS_open || syscall == SYS_openat || syscall == SYS_openat2
            || syscall == SYS_creat) {
        // return TRACE_OK;
        
        int path_register;
        int flags;

        if (syscall == SYS_openat) {
            flags = regs.rdx;
            path_register = RSI;
        }
        else if (syscall == SYS_openat2) {
            // This is really a pointer to a open_how struct, but its first field is the
            // flags.
            long how_addr = regs.rdx;
            flags = (uint64_t) ptrace(PTRACE_PEEKUSER, pid, how_addr, 0);

            path_register = RSI;
        }
        else if (syscall == SYS_open) {
            flags = regs.rsi;
            path_register = RDI;
        }
        else if (syscall == SYS_creat) {
            // https://manpages.debian.org/unstable/manpages-dev/creat.2.en.html#creat()
            flags = O_CREAT | O_WRONLY | O_TRUNC;  
            path_register = RDI;
        }
        else {
            fprintf(stderr, "Internal error, forgot to handle syscall %ld in open() checks\n", syscall);
            return TRACE_ERROR_FATAL;
        }

        // Get the path they want to open. Some like /dev/ptsNNN are allowed.
        char desired_path[PATH_MAX];
        char *path_addr = (char*) ptrace(PTRACE_PEEKUSER, pid, sizeof(long) * path_register, 0);
        //printf("path addr = %p\n", path_addr);
        int done = 0;
        int i = 0;
        long word;
        //char buf[8];
        while (!done) {
            word = ptrace(PTRACE_PEEKTEXT, pid, path_addr + i, 0);
            desired_path[i] = (char) (word);
            if (!desired_path[i] || i == PATH_MAX) break;
            desired_path[i+1] = (char) (word >> 8);
            if (!desired_path[i+1] || i+1 == PATH_MAX) break;
            desired_path[i+2] = (char) (word >> 16);
            if (!desired_path[i+2] || i+2 == PATH_MAX) break;
            desired_path[i+3] = (char) (word >> 24);
            if (!desired_path[i+3] || i+3 == PATH_MAX) break;
            desired_path[i+4] = (char) (word >> 32);
            if (!desired_path[i+4] || i+4 == PATH_MAX) break;
            desired_path[i+5] = (char) (word >> 40);
            if (!desired_path[i+5] || i+5 == PATH_MAX) break;
            desired_path[i+6] = (char) (word >> 48);
            if (!desired_path[i+6] || i+6 == PATH_MAX) break;
            desired_path[i+7] = (char) (word >> 56);
            if (!desired_path[i+7] || i+7 == PATH_MAX) break;

            i += 8;
            //printf("%s\n", buf);
            //char buf[sizeof(long) / sizeof(char)];
            //memcpy(buf, word, sizeof(long));
            //printf(" <%s>\n", buf);
            // done = 1;
            //printf("+\n");

        }
        if (TRACE_OPENS) {
            int f_rdonly = flags & O_RDONLY;
            int f_wronly = flags & O_WRONLY;
            int f_rdwr = flags & O_RDWR;
            int f_append = flags & O_APPEND;
            int f_async = flags & O_ASYNC;
            int f_cloexec = flags & O_CLOEXEC;
            int f_creat = flags & O_CREAT;
            int f_direct = flags & O_DIRECT;
            int f_directory = flags & O_DIRECTORY;
            int f_dsync = flags & O_DSYNC;
            int f_excl = flags & O_EXCL;
            int f_largefile = flags & O_LARGEFILE;
            int f_noatime = flags & O_NOATIME;
            int f_noctty = flags & O_NOCTTY;
            int f_nofollow = flags & O_NOFOLLOW;
            int f_nonblock = flags & O_NONBLOCK;
            int f_ndelay = flags & O_NDELAY;
            int f_path = flags & O_PATH;
            int f_sync = flags & O_SYNC;
            int f_tmpfile = flags & O_TMPFILE;
            int f_trunc = flags & O_TRUNC;
            printf("open(%s,", desired_path);
            if (f_rdonly) printf(" +ro");
            if (f_wronly) printf(" +wo");
            if (f_rdwr) printf(" +rw");
            if (f_append) printf(" +append");
            if (f_async) printf(" +async");
            if (f_cloexec) printf(" +cloexec");
            if (f_creat) printf(" +creat");
            if (f_direct) printf(" +direct");
            if (f_directory) printf(" +directory");
            if (f_dsync) printf(" +dsync");
            if (f_excl) printf(" +excl");
            if (f_largefile) printf(" +largefile");
            if (f_noatime) printf(" +noatime");
            if (f_noctty) printf(" +noctty");
            if (f_nofollow) printf(" +nofollow");
            if (f_nonblock) printf(" +nonblock");
            if (f_ndelay) printf(" +ndelay");
            if (f_path) printf(" +path");
            if (f_sync) printf(" +sync");
            if (f_tmpfile) printf(" +tmpfile");
            if (f_trunc) printf(" +trunc");
            printf(")\n");
        }
        // printf("open(%s, %x (%x) (%x))\n", desired_path, flags, flags & (O_APPEND | O_RDWR | O_WRONLY | O_CREAT | O_TRUNC), flags & (O_RDONLY));

        // Fully resolve the path to eliminate tomfoolery
        // e.g.
        //  $ mkdir /path/that/should/be/sandboxed
        //  $ ./procbox ln -s /path/that/should/be/sandboxed /tmp/exploit
        //  $ ./procbox touch /tmp/exploit/this_shouldnt_be_allowed
        //  $ stat /tmp/exploit/this_shouldnt_be_allowed  # whoops, it exists!
        // char real_desired_path[PATH_MAX];
        // realpath(desired_path, real_desired_path);

        if (is_allowed_path(desired_path)) {
            return TRACE_OK;
        }

        // Sorry O_RDWR, you're gonna read back null bytes forEVER!
        if (flags & (O_APPEND | O_RDWR | O_WRONLY)) {
            // printf(" -> SPOOF\n");
            // Replace pathname with /dev/null
            // https://www.alfonsobeato.net/c/modifying-system-call-arguments-with-ptrace/
            
            // Step 1: Allocate space for string "/dev/null" on the stack
            char *stack_addr, *file_addr;
            stack_addr = (char*) ptrace(PTRACE_PEEKUSER, pid, sizeof(long)*RSP, 0);
            stack_addr -= 128 + PATH_MAX;
            file_addr = stack_addr;

            // Step 2: Copy string "/dev/null" to the stack
            const char *file = "/dev/null";
            do {
                int i;
                char val[sizeof(long)];

                for (i = 0; i < sizeof(long); ++i, ++file) {
                    val[i] = *file;
                    if (*file == '\0') break;
                }

                ptrace(PTRACE_POKETEXT, pid, stack_addr, *(long *) val);
                stack_addr += sizeof (long);
            } while (*file);

            // Step 3: Replace the pathname argument with the address of that string


            ptrace(PTRACE_POKEUSER, pid, sizeof(long) * path_register, file_addr);
        }
    }
    else switch(syscall) {
        case SYS_unlink:
        case SYS_unlinkat:
        case SYS_mkdir:
        case SYS_mkdirat:
        case SYS_mknodat:
        case SYS_rmdir:
        case SYS_rename:
        case SYS_renameat:
        case SYS_link:
        case SYS_symlink:
        case SYS_truncate:
        case SYS_ftruncate:
        case SYS_fsync:
        case SYS_flock:
        case SYS_chmod:
        case SYS_fchmod:
        case SYS_fchmodat:
        case SYS_fchmodat2:
        case SYS_sync:
        case SYS_process_vm_writev:
            if (SANDBOX_ENABLED) {
                // printf(" -> DENY %ld\n", syscall);
                return spoof_syscall(pid, 0, &regs);
            }
            break;
    }

    return TRACE_OK;
}

int main(int argc, char** argv) {
    if (argc == 1) {
        fprintf(stderr, "usage: %s cmd [args...]      (run command in sandboxed environment)\n", argv[0]);
        fprintf(stderr, "usage: %s -s                 (open bash shell in sandboxed environment)\n", argv[0]);
        return EXIT_FAILURE;
    }

    pid_t childpid = fork();
    if (childpid == 0) {
        ptrace(PTRACE_TRACEME, 0, 0, 0);
        raise(SIGSTOP);

        if (!strcmp(argv[1], "-s")) {
            //setenv("PS1", "S[\\u@\\h \\W]\\$ ", 1);
            setenv("PS1", "\\033[0;33m(procbox) \\033[0m\\h \\W\\$ ", 1);
            char* args[] = {"/bin/bash", "--norc", NULL};
            execvp("/bin/bash", args);
        }
        else {
            execvp(argv[1], argv + 1);
        }
        perror("execvp");
        return EXIT_FAILURE;
    }

    int trace_status;
    int status;
    pid_t next_child;

    while (1) {
        next_child = waitpid(-1, &status, 0);
        if (next_child == -1 && errno == ECHILD) {
            printf("No more children. Exiting.\n");
            break;
        }
        if (WIFEXITED(status)) {
            if (TRACE_CHILD_PIDS)
                printf("<DIE: %d>\n", next_child);
            
            // TODO (optimization): only do this if the pid has a process_state entry
            free_process_state(get_process_state(next_child));

            continue;
        }
        trace_status = trace_syscall(next_child);
        if (trace_status == TRACE_ERROR_FATAL) {
            printf("Fatal error occurred while tracing syscall. Exiting.\n");
            break;
        }
        ptrace(PTRACE_SYSCALL, next_child, 0, 0);
    }


    return 0;
}
