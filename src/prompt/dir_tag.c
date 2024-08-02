#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

int main() {
    char cwd[PATH_MAX+1];
    getcwd(cwd, PATH_MAX);
    int len = strlen(cwd);
    cwd[len] = '/';
    cwd[1+len] = '\0';

    if (
        strstr(cwd, "/prod/")
        || strstr(cwd, "/releases/")
        || strstr(cwd, "/branches/")
        || strstr(cwd, "/deployments/")
        || strstr(cwd, "/install/")
        || strstr(cwd, "/builds/")
    ) {
        printf("(prod dir)\n");
    }

    return 0;
}
