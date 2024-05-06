#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/ptrace.h>
#include <sys/user.h>
#include <sys/syscall.h>
#include <sys/reg.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>

#define TRACE_OK 0
#define TRACE_ERROR_NONFATAL 1
#define TRACE_ERROR_FATAL 2

#define DEBUG_LINKED_LIST 0
#define PRINT_CHILD_PIDS 1
#define SANDBOX_ENABLED 1

struct process_state {
    pid_t pid;
    int changed_stdout_fd : 1;
    int changed_stderr_fd : 1;

    struct process_state *left;
    struct process_state *right;
};

static struct process_state *process_state_start = NULL;

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

void assert(int val, const char* msg) {
    if (!val) {
        printf("ASSERT FAIL: %s\n", msg);
        exit(EXIT_FAILURE);
    }
}

void check_integrity(struct process_state *state, const char* msg) {
    if (DEBUG_LINKED_LIST) {
        printf("checking: %s\n", msg);
        if (state->left != NULL) {
            assert(state->left->right == state, "X->L->R = X");
            assert(state->left->pid < state->pid, "L < R");
        }
        if (state->right != NULL) {
            assert(state->right->left == state, "X->R->L = X");
            assert(state->right->pid > state->pid, "R > L");
        }
        assert(state->left != state, "L != X");
        assert(state->right != state, "R != X");
        assert(state->left != state->right || state->left == NULL, "L != R");
    }
}

void print_list() {
    struct process_state *state = process_state_start;
    if (state == NULL) {
        printf("--no states to print--\n");
        return;
    }
    int DBG_i = 0;
    while (state->left != NULL) {
        state = state->left;
        DBG_i++;
        if (DBG_i > 100) {
            printf("omfg nooo\n");
            exit(EXIT_FAILURE);
        }
    }
    while (state != NULL) {
        printf("%d -> ", state->pid);
        state = state->right;
    }
    printf("\n");
}

// Returns pointer to `pid`'s process state, inserting one if it does not yet exist.
struct process_state *get_process_state(pid_t pid) {
    if (DEBUG_LINKED_LIST) {
        printf("get_process_state(%d)\n", pid);
        print_list();
    }
    struct process_state *buf = process_state_start;
    if (buf == NULL) {
        process_state_start = malloc(sizeof (struct process_state));
        init_process_state(process_state_start, pid);
        return process_state_start;
    }
    int DBG_i = 0;
    while (buf != NULL) {
        
        // debug cause im dum
        if (DEBUG_LINKED_LIST) {
            printf("buf=%d", buf->pid);
            if (buf->left != NULL) {
                printf(" left=%d", buf->left->pid);
            }
            else {
                printf(" left=NULL");
            }
            if (buf->right != NULL) {
                printf(" right=%d\n", buf->right->pid);
            }
            else {
                printf(" right=NULL\n");
            }
            DBG_i++;
            if (DBG_i > 100) {
                printf("you idiot!\n");
                return NULL;
            }
        }


        if (buf->left == NULL && buf->pid > pid) {
            // Insert new at very left
            buf->left = malloc(sizeof (struct process_state));
            init_process_state(buf->left, pid);
            buf->left->right = buf;
            check_integrity(buf->left, "1/1");
            check_integrity(buf, "1/2");
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
            check_integrity(entry, "2/1");
            check_integrity(buf, "2/2");
            check_integrity(buf->left, "2/3");
            check_integrity(buf->right, "2/4");
            return entry;
        }
        if (buf->pid == pid) {
            check_integrity(buf, "3/1");
            return buf;
        }
        if (buf->right == NULL && pid > buf->pid) {
            // Insert new at very right
            buf->right = malloc(sizeof (struct process_state));
            init_process_state(buf->right, pid);
            buf->right->left = buf;
            check_integrity(buf->right, "4/1");
            check_integrity(buf, "4/2");
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
            check_integrity(entry, "5/1");
            check_integrity(buf, "5/2");
            check_integrity(buf->left, "5/3");
            check_integrity(buf->right, "5/4");
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

    int status;
    struct user_regs_struct regs;
    status = ptrace(PTRACE_GETREGS, pid, 0, &regs);
    if (status) {
        perror("ptrace(getregs) during trace_syscall()");
        return TRACE_ERROR_NONFATAL;
    }
    long syscall = regs.orig_rax;
    //printf("Pid %d: Syscall %ld\n", pid, syscall);

    if (syscall == SYS_fork || syscall == SYS_vfork || syscall == SYS_clone) {
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
        
        if (PRINT_CHILD_PIDS)
            printf("<NEW: %d>\n", fork_child);
        ptrace(PTRACE_ATTACH, fork_child, 0, 0);

    }
    else if (syscall == SYS_write || syscall == SYS_tee) {
        int fd = (syscall == SYS_write ? regs.rdi : regs.rsi);
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

    // SYS_openat2 DNE???
    else if (syscall == SYS_open || syscall == SYS_openat || syscall == SYS_creat) {
        int flags;
        if (syscall == SYS_openat) {  // SYS_openat2 DNE???
            flags = (syscall == SYS_openat ? regs.rdx : regs.r10);
            // Replace syscall with SYS_open and change the relevant registers
            regs.orig_rax = SYS_getpid;
            ptrace(PTRACE_SETREGS, pid, NULL, regs);

            regs.rdi = regs.rsi;
            regs.rsi = regs.rdx;
        }
        else {
            flags = regs.rsi;
        }

        // Sorry O_RDWR, you're gonna read back null bytes forEVER!
        if (flags & (O_APPEND | O_RDWR | O_WRONLY)) {
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
            ptrace(PTRACE_POKEUSER, pid, sizeof(long)*RDI, file_addr);
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
        case SYS_sync:
            if (SANDBOX_ENABLED)
                return spoof_syscall(pid, 0, &regs);
            break;
    }

    return TRACE_OK;
}

int main(int argc, char** argv) {
    pid_t childpid = fork();
    if (childpid == 0) {
        ptrace(PTRACE_TRACEME, 0, 0, 0);
        raise(SIGSTOP);

        execvp(argv[1], argv + 1);
        perror("execvp");
        return EXIT_FAILURE;
    }

    //ptrace(PTRACE_SYSCALL, childpid, 0, 0);

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
            if (PRINT_CHILD_PIDS)
                printf("<DIE: %d>\n", next_child);
            
            // TODO (optimization): only do this if the pid has a process_state entry
            free_process_state(get_process_state(next_child));

            //printf("Child %d exited.\n", next_child);
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
