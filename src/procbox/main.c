#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <seccomp.h>
#include <sys/prctl.h>
#include <linux/audit.h>
#include <linux/filter.h>
#include <linux/seccomp.h>
#include <sys/syscall.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        return 1;
    }

    // Initialize the seccomp context
    scmp_filter_ctx ctx;
    ctx = seccomp_init(SCMP_ACT_ALLOW);
    if (ctx == NULL) {
        perror("seccomp_init failed");
        return 1;
    }

    // Define a list of file-mutating syscalls to block
    int syscalls_to_block[] = {SCMP_SYS(chmod), SCMP_SYS(unlink), SCMP_SYS(rename), SCMP_SYS(write)};
    int num_syscalls = sizeof(syscalls_to_block) / sizeof(int);
    
    for (int i = 0; i < num_syscalls; i++) {
        // Allow write() only to stdout and stderr
        if (syscalls_to_block[i] == SCMP_SYS(write)) {
            seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 1, SCMP_A0(SCMP_CMP_EQ, STDOUT_FILENO));
            seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 1, SCMP_A0(SCMP_CMP_EQ, STDERR_FILENO));
        } else {
            seccomp_rule_add(ctx, SCMP_ACT_ERRNO(0), syscalls_to_block[i], 0);
        }
    }

    // Apply the seccomp filter
    if (seccomp_load(ctx) != 0) {
        perror("seccomp_load failed");
        seccomp_release(ctx);
        return 1;
    }

    // Execute the desired command
    execvp(argv[1], &argv[1]);

    // Cleanup
    seccomp_release(ctx);
    perror("execvp failed");
    return 1;
}
