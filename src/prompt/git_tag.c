#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

int main() {
    char cwd[PATH_MAX];
    getcwd(cwd, PATH_MAX);
    
    char git[PATH_MAX];

    struct stat statbuf;

    dev_t dev = 0;

    while (cwd[1] != '\0') {  // ie cwd == "/"
        strcpy(git, cwd);

	if (!stat(cwd, &statbuf)) {
	    if (dev && dev != statbuf.st_dev) {
	        break;
	    }
	    dev = statbuf.st_dev;
	}

        strcat(git, "/.git/HEAD");

        if (!stat(git, &statbuf)) {
            FILE *fp = fopen(git, "r");
            char head[1024];
            fread(&head, 1024, 1024, fp);
            head[strlen(head) - 1] = '\0';  // remove trailing newline
            
            char head_short[1024];
            char *refstart = strstr(head, "refs/heads/");
            if (!refstart) return 0;
            strcpy(head_short, refstart + strlen("refs/heads/"));

            printf("(%s)\n", head_short);
            return 0;
        }

        dirname(cwd);
    }

    return 0;
}
