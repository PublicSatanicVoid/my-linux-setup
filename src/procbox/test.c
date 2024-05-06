#include <stdio.h>
#include <stdlib.h>
#include <linux/seccomp.h>
#include <seccomp.h>
#include <sys/prctl.h>

int main() {
    printf("ENTERING\n");
    FILE *filePoint;

    filePoint = fopen("/tmp/test.txt", "a");

    if(filePoint == NULL) {
        puts("File can not be opened");
        exit(1);
    }

    fputs("qwe\n", filePoint);

    fclose(filePoint);

    filePoint = fopen("/tmp/test.txt", "a");

    if(filePoint == NULL) {
        puts("File can not be opened");
        exit(1);
    }

    scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_KILL);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(fstat), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(close), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(exit_group), 0);
    seccomp_load(ctx);
    
    fputs("xyz", filePoint);

    fclose(filePoint);

    return 0;
}
