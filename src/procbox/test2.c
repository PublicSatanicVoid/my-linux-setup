#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/ptrace.h>
#include <sys/user.h>
#include <sys/syscall.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        return 1;
    }

    pid_t child = fork();
    if (child == 0) {
        // Child: Set up to be traced
        ptrace(PTRACE_TRACEME, 0, NULL, NULL);

        printf("child: I am being traced\n");

        raise(SIGSTOP);

        printf("child: Resumed from SIGSTOP\n");
        

        //int status = rename("foo", "bar");
        //printf("child: rename() status=%d\n", status);

        //pid_t pid = getpid();
        //printf("child: getpid() = %d\n", pid);
        //exit(0);


        execvp(argv[1], argv + 1);
        perror("execvp failed");
        exit(1);
    } else if (child > 0) {
        // Parent: Trace child
        int status;
        unsigned long options = PTRACE_O_TRACEFORK | PTRACE_O_TRACEVFORK | PTRACE_O_TRACEEXEC | PTRACE_O_TRACECLONE;
        ptrace(PTRACE_SETOPTIONS, child, 0, options);
        waitpid(child, &status, 0);
        if (WIFSTOPPED(status)) {
            printf("parent: Saw child initial stop\n");
            ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_TRACESYSGOOD);
            while (1) {
                ptrace(PTRACE_SYSCALL, child, 0, 0);
                waitpid(child, &status, 0);
                if (WIFEXITED(status)) {
                    printf("parent: Child has exited.\n");
                    break;
                }

                struct user_regs_struct regs;
                ptrace(PTRACE_GETREGS, child, NULL, &regs);

                //printf("parent: Saw child syscall, rax=%ld\n", regs.orig_rax);

                switch(regs.orig_rax) {
                    case SYS_fork:
                    case SYS_vfork:
                    case SYS_clone:
                        printf("parent: Saw fork of child\n");
                        break;
                    case SYS_execve:
                    //case SYS_execveat:
                        printf("parent: Saw exec of child\n");
                        ptrace(PTRACE_EVENT_EXEC, child, 0, 0);
                        printf(" - waiting for exec...\n");
                        waitpid(child, &status, 0);
                        printf(" - waitpid status now %d\n", status);
                        unsigned long grandchild_pid;
                        status = ptrace(PTRACE_GETEVENTMSG, child, 0, &grandchild_pid);
                        if (status != 0) {
                            perror("ptrace(geteventmsg)");
                        }
                        printf("parent: - New grandchild is %lu\n", grandchild_pid);
                        break;
                    case SYS_write:
                        printf("parent: Saw write syscall to fd %llu\n", regs.rdi);
                        if (regs.rdi != STDOUT_FILENO && regs.rdi != STDERR_FILENO) {
                            printf("parent: - This is not a write to stdout/err\n");
                        }
                        break;
                    case SYS_rename:
                    case SYS_renameat:
                        printf("parent: - Saw rename syscall\n");
                        regs.orig_rax = SYS_getpid;
                        ptrace(PTRACE_SETREGS, child, NULL, &regs);
                        printf("parent: - Modified child regs\n");
                        ptrace(PTRACE_SYSCALL, child, 0, 0);
                        waitpid(child, &status, 0);
                        if (WIFEXITED(status)) {
                            printf("parent: Unexpected child exit\n");
                            break;
                        }
                        if (regs.orig_rax == SYS_getpid) {
                            ptrace(PTRACE_GETREGS, child, NULL, &regs);
                            regs.rax = 0;
                            ptrace(PTRACE_SETREGS, child, NULL, &regs);
                        }
                        else {
                            printf("parent: Unexpected next syscall %llu\n", regs.orig_rax);
                        }
                        break;
                }
            }
        }
        //while (waitpid(child, &status, 0) && !WIFEXITED(status)) {
        //    if (WIFSTOPPED(status)) {
        //        struct user_regs_struct regs;
        //        ptrace(PTRACE_GETREGS, child, NULL, &regs);

        //        // Check syscall number and modify behavior
        //        switch (regs.orig_rax) {
        //            case SYS_write:
        //            case SYS_writev:
        //                // Allow writes only to stdout or stderr
        //                if (regs.rdi != STDOUT_FILENO && regs.rdi != STDERR_FILENO) {
        //                    regs.orig_rax = SYS_getpid; // Change syscall to getpid (a typical no-op)
        //                    ptrace(PTRACE_SETREGS, child, NULL, &regs);
        //                }
        //                break;
        //            case SYS_unlink:
        //            case SYS_unlinkat:
        //            case SYS_chmod:
        //            case SYS_fchmod:
        //            case SYS_fchmodat:
        //            case SYS_flock:
        //            case SYS_fsync:
        //            case SYS_fsetxattr:
        //            case SYS_ftruncate:
        //            //case SYS_ftruncate64:
        //            case SYS_link:
        //            case SYS_linkat:
        //            case SYS_lremovexattr:
        //            case SYS_lsetxattr:
        //            case SYS_mkdir:
        //            case SYS_mkdirat:
        //            //case SYS_open:
        //            //case SYS_open_by_handle_at:
        //            //case SYS_openat:
        //            //case SYS_openat2:
        //            //case SYS_send:
        //            case SYS_rmdir:
        //            case SYS_rename:
        //            case SYS_renameat:
        //            case SYS_setxattr:
        //            case SYS_sync:
        //                printf("changing syscall, %ld, to %ld\n", regs.orig_rax, SYS_getpid);
        //                regs.orig_rax = SYS_getpid; // Change syscall to getpid
        //                ptrace(PTRACE_SETREGS, child, NULL, &regs);
        //                break;
        //        }
        //        ptrace(PTRACE_SYSCALL, child, NULL, NULL); // Continue to next syscall
        //    }
        //}
    } else {
        perror("fork failed");
        return 1;
    }
    return 0;
}
