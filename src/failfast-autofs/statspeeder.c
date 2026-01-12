#define _GNU_SOURCE

#include <dlfcn.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <linux/limits.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
//#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdarg.h>
#include <wchar.h>


typedef int (*__xstat_t)(int ver, const char *file, struct stat *buf);
typedef int (*__xstat64_t)(int ver, const char *file, struct stat64 *buf);
typedef int (*statx_t)(
    int dirfd,
    const char *path,
    int flags,
    unsigned int mask,
    struct statx *statxbuf
);
typedef int (*openat_t)(int dirfd, const char *path, int flags, ...);
typedef int (*_Py_wstat_t)(const wchar_t* path, struct stat *buf);


// Could set to something other than -1 to debug client programs (normally they would
// get a return value of -1 on error)
static const int FAIL_FAST_RETURN_CODE = -1;

static const char* const FAST_FAIL_PATHS[] = {
    "/projects/.editorconfig",
    "/projects/pyproject.toml",
    "/projects/ruff.toml",
    "/projects/.ruff.toml",
    "/projects/.git",
    "/projects/.git/info/exclude",
    "/projects/.ignore",
    "/projects/.gitignore",
    "/projects/.rgignore",
    "/projects/lib",
    "/projects/lib/python310.zip",
    "/projects/lib/python311.zip",
    "/projects/lib/python312.zip",
    "/projects/lib/python313.zip",
    "/projects/setup.py",
    "/projects/setup.cfg",
    "/projects/requirements.txt",
    "/projects/Pipfile",

    "/home/.editorconfig",
    "/home/pyproject.toml",
    "/home/ruff.toml",
    "/home/.ruff.toml",
    "/home/.git",
    "/home/.git/info/exclude",
    "/home/.ignore",
    "/home/.gitignore",
    "/home/.rgignore",
    "/home/lib",
    "/home/lib/python310.zip",
    "/home/lib/python311.zip",
    "/home/lib/python312.zip",
    "/home/lib/python313.zip",
    "/home/setup.py",
    "/home/setup.cfg",
    "/home/requirements.txt",
    "/home/Pipfile"
};

#define countof(arr) (sizeof(arr)/sizeof((arr)[0]))
#define min(x,y) ((x)<(y)?(x):(y))


static int is_fail_fast_path(const char *path) {
    if (!path) {
        return 0;
    }

    for (int i = 0; i < countof(FAST_FAIL_PATHS); ++i) {
        if (!strncmp(path, FAST_FAIL_PATHS[i], PATH_MAX)) {
            return 1;
        }
    }
    return 0;
}



int __xstat(int ver, const char *path, struct stat *buf) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    __xstat_t real___xstat = (__xstat_t) dlsym(RTLD_NEXT, "__xstat");
    if (!real___xstat) {
        errno = EIO;
        return -1;
    }

    return real___xstat(ver, path, buf);
}

int __xstat64(int ver, const char *path, struct stat64 *buf) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    __xstat64_t real___xstat64 = (__xstat64_t) dlsym(RTLD_NEXT, "__xstat64");
    if (!real___xstat64) {
        errno = EIO;
        return -1;
    }

    return real___xstat64(ver, path, buf);
}

int _Py_wstat(const wchar_t *path, struct stat *buf) {
    char conv[4096];
    size_t len = wcslen(path);
    wcstombs(conv, path, len);
    
    if (is_fail_fast_path(conv)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    _Py_wstat_t real__Py_wstat = (_Py_wstat_t) dlsym(RTLD_NEXT, "_Py_wstat");
    if (!real__Py_wstat) {
        errno = EIO;
        return -1;
    }

    return real__Py_wstat(path, buf);
}

int statx(
    int dirfd,
    const char *path,
    int flags,
    unsigned int mask,
    struct statx *statxbuf
) {

    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    statx_t real_statx = (statx_t) dlsym(RTLD_NEXT, "statx");
    if (!real_statx) {
        errno = EIO;
        return -1;
    }

    return real_statx(dirfd, path, flags, mask, statxbuf);
    
}





// All these openat... have identical signatures


int openat(int dirfd, const char *path, int flags, ...) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    openat_t real_openat = (openat_t) dlsym(RTLD_NEXT, "openat");
    if (!real_openat) {
        errno = EIO;
        return -1;
    }

    va_list args;
    va_start(args, flags);
    int fd;
    if (flags & O_CREAT) {
        mode_t mode = va_arg(args, mode_t);
        fd = real_openat(dirfd, path, flags, mode);
    }
    else {
        fd = real_openat(dirfd, path, flags);
    }
    va_end(args);
    return fd;
}

int __openat(int dirfd, const char *path, int flags, ...) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    openat_t real_openat = (openat_t) dlsym(RTLD_NEXT, "__openat");
    if (!real_openat) {
        errno = EIO;
        return -1;
    }

    va_list args;
    va_start(args, flags);
    int fd;
    if (flags & O_CREAT) {
        mode_t mode = va_arg(args, mode_t);
        fd = real_openat(dirfd, path, flags, mode);
    }
    else {
        fd = real_openat(dirfd, path, flags);
    }
    va_end(args);
    return fd;
}

int openat64(int dirfd, const char *path, int flags, ...) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    openat_t real_openat = (openat_t) dlsym(RTLD_NEXT, "openat64");
    if (!real_openat) {
        errno = EIO;
        return -1;
    }

    va_list args;
    va_start(args, flags);
    int fd;
    if (flags & O_CREAT) {
        mode_t mode = va_arg(args, mode_t);
        fd = real_openat(dirfd, path, flags, mode);
    }
    else {
        fd = real_openat(dirfd, path, flags);
    }
    va_end(args);
    return fd;
}

int __openat64(int dirfd, const char *path, int flags, ...) {
    if (is_fail_fast_path(path)) {
        errno = ENOENT;
        return FAIL_FAST_RETURN_CODE;
    }

    openat_t real_openat = (openat_t) dlsym(RTLD_NEXT, "__openat64");
    if (!real_openat) {
        errno = EIO;
        return -1;
    }

    va_list args;
    va_start(args, flags);
    int fd;
    if (flags & O_CREAT) {
        mode_t mode = va_arg(args, mode_t);
        fd = real_openat(dirfd, path, flags, mode);
    }
    else {
        fd = real_openat(dirfd, path, flags);
    }
    va_end(args);
    return fd;
}

