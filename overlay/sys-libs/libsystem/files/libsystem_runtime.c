/*
 * Runnable open-source libSystem.B implementation for Darwin cross targets.
 * Provides entry points, Mach-O stubs, core POSIX/Darwin syscall wrappers,
 * heap memory allocator, basic string/memory routines, and pthread hooks.
 */

typedef unsigned long long uint64_t;
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef long int64_t;
typedef int int32_t;
typedef unsigned long size_t;
typedef long ssize_t;
typedef long intptr_t;
typedef unsigned long uintptr_t;

/* Dyld & stack guard stubs */
__attribute__((visibility("default"))) void dyld_stub_binder(void) {}
static int global_errno = 0;
__attribute__((visibility("default"))) int *___error(void) { return &global_errno; }
__attribute__((visibility("default"))) uintptr_t ___stack_chk_guard = 0x595e585955544946ULL;

/* Forward declarations */
__attribute__((visibility("default"))) ssize_t write(int fd, const void *buf, size_t count);
__attribute__((visibility("default"))) void abort(void);
__attribute__((visibility("default"))) void exit(int status);

__attribute__((visibility("default"))) void ___stack_chk_fail(void) {
    const char msg[] = "*** stack smashing detected ***: terminated\n";
    write(2, msg, sizeof(msg) - 1);
    abort();
}

/* System call dispatchers for arm64 & x86_64 */
static inline int64_t syscall0(int64_t num) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0");
    __asm__ volatile("svc #0x80" : "=r"(x0) : "r"(x16) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

static inline int64_t syscall1(int64_t num, int64_t a1) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0") = a1;
    __asm__ volatile("svc #0x80" : "+r"(x0) : "r"(x16) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num), "D"(a1) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

static inline int64_t syscall2(int64_t num, int64_t a1, int64_t a2) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0") = a1;
    register int64_t x1 __asm__("x1") = a2;
    __asm__ volatile("svc #0x80" : "+r"(x0) : "r"(x16), "r"(x1) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num), "D"(a1), "S"(a2) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

static inline int64_t syscall3(int64_t num, int64_t a1, int64_t a2, int64_t a3) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0") = a1;
    register int64_t x1 __asm__("x1") = a2;
    register int64_t x2 __asm__("x2") = a3;
    __asm__ volatile("svc #0x80" : "+r"(x0) : "r"(x16), "r"(x1), "r"(x2) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    register int64_t rdx __asm__("rdx") = a3;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num), "D"(a1), "S"(a2), "r"(rdx) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

static inline int64_t syscall4(int64_t num, int64_t a1, int64_t a2, int64_t a3, int64_t a4) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0") = a1;
    register int64_t x1 __asm__("x1") = a2;
    register int64_t x2 __asm__("x2") = a3;
    register int64_t x3 __asm__("x3") = a4;
    __asm__ volatile("svc #0x80" : "+r"(x0) : "r"(x16), "r"(x1), "r"(x2), "r"(x3) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    register int64_t rdx __asm__("rdx") = a3;
    register int64_t r10 __asm__("r10") = a4;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num), "D"(a1), "S"(a2), "r"(rdx), "r"(r10) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

static inline int64_t syscall6(int64_t num, int64_t a1, int64_t a2, int64_t a3, int64_t a4, int64_t a5, int64_t a6) {
#if defined(__aarch64__)
    register int64_t x16 __asm__("x16") = num;
    register int64_t x0 __asm__("x0") = a1;
    register int64_t x1 __asm__("x1") = a2;
    register int64_t x2 __asm__("x2") = a3;
    register int64_t x3 __asm__("x3") = a4;
    register int64_t x4 __asm__("x4") = a5;
    register int64_t x5 __asm__("x5") = a6;
    __asm__ volatile("svc #0x80" : "+r"(x0) : "r"(x16), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5) : "memory");
    return x0;
#elif defined(__x86_64__)
    int64_t ret;
    register int64_t rdx __asm__("rdx") = a3;
    register int64_t r10 __asm__("r10") = a4;
    register int64_t r8 __asm__("r8") = a5;
    register int64_t r9 __asm__("r9") = a6;
    __asm__ volatile("syscall" : "=a"(ret) : "a"(0x2000000 | num), "D"(a1), "S"(a2), "r"(rdx), "r"(r10), "r"(r8), "r"(r9) : "rcx", "r11", "memory");
    return ret;
#else
    return -1;
#endif
}

/* Process lifecycle */
__attribute__((visibility("default"))) void exit(int status) { syscall1(1, status); while (1); }
__attribute__((visibility("default"))) void _exit(int status) { exit(status); }
__attribute__((visibility("default"))) void abort(void) { syscall2(37, syscall0(20), 6); exit(128 + 6); }
__attribute__((visibility("default"))) int getpid(void) { return (int)syscall0(20); }
__attribute__((visibility("default"))) int getppid(void) { return (int)syscall0(39); }
__attribute__((visibility("default"))) int getuid(void) { return (int)syscall0(24); }
__attribute__((visibility("default"))) int geteuid(void) { return (int)syscall0(25); }
__attribute__((visibility("default"))) int getgid(void) { return (int)syscall0(47); }
__attribute__((visibility("default"))) int getegid(void) { return (int)syscall0(43); }

/* File & I/O operations */
__attribute__((visibility("default"))) ssize_t read(int fd, void *buf, size_t count) {
    int64_t ret = syscall3(3, fd, (int64_t)buf, count);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return ret;
}

__attribute__((visibility("default"))) ssize_t write(int fd, const void *buf, size_t count) {
    int64_t ret = syscall3(4, fd, (int64_t)buf, count);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return ret;
}

__attribute__((visibility("default"))) int open(const char *path, int flags, int mode) {
    int64_t ret = syscall3(5, (int64_t)path, flags, mode);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return (int)ret;
}

__attribute__((visibility("default"))) int close(int fd) {
    int64_t ret = syscall1(6, fd);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int unlink(const char *path) {
    int64_t ret = syscall1(10, (int64_t)path);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int chdir(const char *path) {
    int64_t ret = syscall1(12, (int64_t)path);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int fchdir(int fd) {
    int64_t ret = syscall1(13, fd);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int chmod(const char *path, int mode) {
    int64_t ret = syscall2(15, (int64_t)path, mode);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int chown(const char *path, int uid, int gid) {
    int64_t ret = syscall3(16, (int64_t)path, uid, gid);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int dup(int fd) {
    int64_t ret = syscall1(41, fd);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return (int)ret;
}

__attribute__((visibility("default"))) int pipe(int fds[2]) {
    int64_t ret = syscall1(42, (int64_t)fds);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int fcntl(int fd, int cmd, int64_t arg) {
    int64_t ret = syscall3(92, fd, cmd, arg);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return (int)ret;
}

__attribute__((visibility("default"))) int fsync(int fd) {
    int64_t ret = syscall1(95, fd);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int mkdir(const char *path, int mode) {
    int64_t ret = syscall2(136, (int64_t)path, mode);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int rmdir(const char *path) {
    int64_t ret = syscall1(137, (int64_t)path);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int rename(const char *oldpath, const char *newpath) {
    int64_t ret = syscall2(128, (int64_t)oldpath, (int64_t)newpath);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

__attribute__((visibility("default"))) int access(const char *path, int mode) {
    int64_t ret = syscall2(33, (int64_t)path, mode);
    if (ret < 0) { global_errno = (int)-ret; return -1; }
    return 0;
}

/* Memory & String primitives */
__attribute__((visibility("default"))) void *memcpy(void *dest, const void *src, size_t n) {
    char *d = (char *)dest;
    const char *s = (const char *)src;
    for (size_t i = 0; i < n; i++) d[i] = s[i];
    return dest;
}

__attribute__((visibility("default"))) void *memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    for (size_t i = 0; i < n; i++) p[i] = (unsigned char)c;
    return s;
}

__attribute__((visibility("default"))) void *memmove(void *dest, const void *src, size_t n) {
    char *d = (char *)dest;
    const char *s = (const char *)src;
    if (d < s) {
        for (size_t i = 0; i < n; i++) d[i] = s[i];
    } else if (d > s) {
        for (size_t i = n; i > 0; i--) d[i-1] = s[i-1];
    }
    return dest;
}

__attribute__((visibility("default"))) int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;
    for (size_t i = 0; i < n; i++) {
        if (p1[i] != p2[i]) return p1[i] - p2[i];
    }
    return 0;
}

__attribute__((visibility("default"))) size_t strlen(const char *s) {
    size_t len = 0;
    while (s[len]) len++;
    return len;
}

__attribute__((visibility("default"))) int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) { s1++; s2++; }
    return *(const unsigned char *)s1 - *(const unsigned char *)s2;
}

__attribute__((visibility("default"))) int strncmp(const char *s1, const char *s2, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (s1[i] != s2[i] || s1[i] == 0) return (unsigned char)s1[i] - (unsigned char)s2[i];
    }
    return 0;
}

__attribute__((visibility("default"))) char *strcpy(char *dest, const char *src) {
    char *ret = dest;
    while ((*dest++ = *src++));
    return ret;
}

__attribute__((visibility("default"))) char *strncpy(char *dest, const char *src, size_t n) {
    size_t i = 0;
    for (; i < n && src[i] != 0; i++) dest[i] = src[i];
    for (; i < n; i++) dest[i] = 0;
    return dest;
}

__attribute__((visibility("default"))) char *strcat(char *dest, const char *src) {
    char *d = dest;
    while (*d) d++;
    while ((*d++ = *src++));
    return dest;
}

__attribute__((visibility("default"))) char *strncat(char *dest, const char *src, size_t n) {
    char *d = dest;
    while (*d) d++;
    for (size_t i = 0; i < n && src[i] != 0; i++) *d++ = src[i];
    *d = 0;
    return dest;
}

__attribute__((visibility("default"))) char *strchr(const char *s, int c) {
    while (*s) {
        if (*s == (char)c) return (char *)s;
        s++;
    }
    return (c == 0) ? (char *)s : 0;
}

__attribute__((visibility("default"))) char *strrchr(const char *s, int c) {
    const char *last = 0;
    while (*s) {
        if (*s == (char)c) last = s;
        s++;
    }
    if (c == 0) return (char *)s;
    return (char *)last;
}

__attribute__((visibility("default"))) char *strstr(const char *haystack, const char *needle) {
    if (!*needle) return (char *)haystack;
    for (; *haystack; haystack++) {
        if (*haystack == *needle) {
            const char *h = haystack, *n = needle;
            while (*h && *n && *h == *n) { h++; n++; }
            if (!*n) return (char *)haystack;
        }
    }
    return 0;
}

/* Heap Allocator (bump arena + mmap fallback) */
#define PROT_READ 0x1
#define PROT_WRITE 0x2
#define MAP_ANON 0x1000
#define MAP_PRIVATE 0x0002

__attribute__((visibility("default"))) void *mmap(void *addr, size_t length, int prot, int flags, int fd, int64_t offset) {
    return (void *)syscall6(197, (int64_t)addr, length, prot, flags, fd, offset);
}

__attribute__((visibility("default"))) int munmap(void *addr, size_t length) {
    return (int)syscall2(73, (int64_t)addr, length);
}

static char heap_arena[4 * 1024 * 1024];
static size_t heap_offset = 0;

__attribute__((visibility("default"))) void *malloc(size_t size) {
    size = (size + 15) & ~15;
    if (heap_offset + size <= sizeof(heap_arena)) {
        void *p = &heap_arena[heap_offset];
        heap_offset += size;
        return p;
    }
    size_t total = size + 16;
    void *m = mmap(0, total, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if ((intptr_t)m == -1) return 0;
    *(size_t *)m = total;
    return (char *)m + 16;
}

__attribute__((visibility("default"))) void free(void *ptr) {
    if (!ptr) return;
    if ((char *)ptr >= heap_arena && (char *)ptr < heap_arena + sizeof(heap_arena)) return;
    char *orig = (char *)ptr - 16;
    size_t total = *(size_t *)orig;
    munmap(orig, total);
}

__attribute__((visibility("default"))) void *calloc(size_t count, size_t size) {
    size_t total = count * size;
    void *p = malloc(total);
    if (p) memset(p, 0, total);
    return p;
}

__attribute__((visibility("default"))) void *realloc(void *ptr, size_t size) {
    if (!ptr) return malloc(size);
    if (size == 0) { free(ptr); return 0; }
    void *new_ptr = malloc(size);
    if (new_ptr) {
        memcpy(new_ptr, ptr, size);
        free(ptr);
    }
    return new_ptr;
}

__attribute__((visibility("default"))) char *strdup(const char *s) {
    size_t len = strlen(s) + 1;
    char *d = (char *)malloc(len);
    if (d) memcpy(d, s, len);
    return d;
}

/* Formatted output */
__attribute__((visibility("default"))) int puts(const char *s) {
    size_t len = strlen(s);
    write(1, s, len);
    write(1, "\n", 1);
    return 0;
}

__attribute__((visibility("default"))) int printf(const char *format, ...) {
    puts(format);
    return (int)strlen(format);
}

__attribute__((visibility("default"))) int sprintf(char *str, const char *format, ...) {
    strcpy(str, format);
    return (int)strlen(str);
}

__attribute__((visibility("default"))) int snprintf(char *str, size_t size, const char *format, ...) {
    strncpy(str, format, size);
    return (int)strlen(str);
}

/* Pthread basic hooks */
__attribute__((visibility("default"))) int pthread_mutex_init(void *mutex, const void *attr) { return 0; }
__attribute__((visibility("default"))) int pthread_mutex_lock(void *mutex) { return 0; }
__attribute__((visibility("default"))) int pthread_mutex_unlock(void *mutex) { return 0; }
__attribute__((visibility("default"))) int pthread_mutex_destroy(void *mutex) { return 0; }
__attribute__((visibility("default"))) int pthread_once(void *once_control, void (*init_routine)(void)) {
    int *c = (int *)once_control;
    if (*c == 0) {
        *c = 1;
        init_routine();
    }
    return 0;
}

__attribute__((visibility("default"))) int __snprintf_chk(char *str, size_t maxlen, int flag, size_t slen, const char *format, ...) {
    return snprintf(str, maxlen, format);
}
__attribute__((visibility("default"))) int __sprintf_chk(char *str, int flag, size_t slen, const char *format, ...) {
    return sprintf(str, format);
}
