#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <errno.h>

int main(int argc, char** argv) {
    struct stat statbuf;
    int result = stat(argv[1], &statbuf);
    printf("stat result = %d\n", result);
    if (result) {
        perror("stat failed");
    }

    result = openat(AT_FDCWD, argv[1], O_RDONLY);
    printf("openat result = %d\n", result);
    if (result) {
        perror("openat failed");
    }


    return 0;
}
