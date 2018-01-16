/*	CoreFoundation_Prefix.h
	Copyright (c) 2005-2016, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2016 Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#ifndef __COREFOUNDATION_PREFIX_H__
#define __COREFOUNDATION_PREFIX_H__ 1

#define _DARWIN_UNLIMITED_SELECT 1

#if (DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI || DEPLOYMENT_TARGET_WINDOWS)
#if DEPLOYMENT_RUNTIME_SWIFT
#if DEPLOYMENT_ENABLE_LIBDISPATCH
#define __HAS_DISPATCH__ 1
#else
#define __HAS_DISPATCH__ 0
#endif
#else
#define __HAS_DISPATCH__ 1
#endif
#endif
#if DEPLOYMENT_TARGET_LINUX && DEPLOYMENT_RUNTIME_SWIFT && DEPLOYMENT_ENABLE_LIBDISPATCH
#define __HAS_DISPATCH__ 1
#endif

#include <CoreFoundation/CFBase.h>


#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#if DEPLOYMENT_TARGET_WINDOWS && defined(__cplusplus)
extern "C" {
#endif

#if DEPLOYMENT_TARGET_IPHONESIMULATOR // work around <rdar://problem/16507706>
#include <pthread.h>
#include <pthread/qos.h>
#define qos_class_self() (QOS_CLASS_UTILITY)
#define qos_class_main() (QOS_CLASS_UTILITY)
#define pthread_set_qos_class_self_np(A, B) do {} while (0)
#define pthread_override_qos_class_start_np(A, B, C) (NULL)
#define pthread_override_qos_class_end_np(A) do {} while (0)
#elif (DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED)
#include <pthread.h>
#include <pthread/qos.h>
#endif

#define SystemIntegrityCheck(A, B)	do {} while (0)

    
#if INCLUDE_OBJC
#include <objc/objc.h>
#else
typedef signed char	BOOL; 
typedef char * id;
typedef char * Class;
#ifndef YES
#define YES (BOOL)1
#endif
#ifndef NO
#define NO (BOOL)0
#endif
#ifndef nil
#define nil NULL
#endif
#endif

#define CRSetCrashLogMessage(A) do {} while (0)
#define CRSetCrashLogMessage2(A) do {} while (0)

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
#import <libkern/OSAtomic.h>
#import <pthread.h>
#endif

    
/* This macro creates some helper functions which are useful in dealing with libdispatch:
 *  __ PREFIX Queue -- manages and returns a singleton serial queue
 *
 * Use the macro like this:
 *   DISPATCH_HELPER_FUNCTIONS(fh, NSFileHandle)
 */

#if __HAS_DISPATCH__
    
#define DISPATCH_HELPER_FUNCTIONS(PREFIX, QNAME)			\
static dispatch_queue_t __ ## PREFIX ## Queue(void) {			\
    static volatile dispatch_queue_t __ ## PREFIX ## dq = NULL;		\
    if (!__ ## PREFIX ## dq) {						\
        dispatch_queue_t dq = dispatch_queue_create("com.apple." # QNAME, NULL); \
        void * volatile *loc = (void * volatile *)&__ ## PREFIX ## dq;	\
        if (!OSAtomicCompareAndSwapPtrBarrier(NULL, dq, loc)) {		\
            dispatch_release(dq);					\
        }								\
    }									\
    return __ ## PREFIX ## dq;						\
}

#else

#define DISPATCH_HELPER_FUNCTIONS(PREFIX, QNAME)
    
#endif
    
    
// hint to the analyzer that the caller is no longer responsable for the object and that it will be transfered to the reciver that is opaque to the caller
#if __clang_analyzer__
#define CF_TRANSFER_OWNERSHIP(obj) (typeof(obj))[(id)obj autorelease]
#else
#define CF_TRANSFER_OWNERSHIP(obj) obj
#endif
    
// hint to the analyzer that the retain/releases are balanced in other locations; the string should be searchable to identify the coorisponding location for the retain/release. These macros should be used with great caution in that they distort the actual retain/release nature of what is happening to the analyzer. Reasonable locations would be in the cases where a value needs to be retained over the lifespan of an external event like a remote machine/process etc.
// NOTE: these seem like they may be backwards - however they are intended to be promises to the analyzer of what will come to pass
#if __clang_analyzer__
#define CF_RELEASE_BALANCED_ELSEWHERE(obj, identified_location) if (obj) CFRetain(obj)
#else
#define CF_RELEASE_BALANCED_ELSEWHERE(obj, identified_location) do { } while (0)
#endif
    
#if __clang_analyzer__
#define CF_RETAIN_BALANCED_ELSEWHERE(obj, identified_location) if (obj) CFRelease(obj)
#else
#define CF_RETAIN_BALANCED_ELSEWHERE(obj, identified_location) do { } while (0)
#endif

#if DEPLOYMENT_TARGET_WINDOWS
// Compatibility with boolean.h
#if defined(__x86_64__)
typedef unsigned int	boolean_t;
#else
typedef int		boolean_t;
#endif
#endif
    
#if DEPLOYMENT_TARGET_FREEBSD
#include <string.h>
#include <sys/stat.h> // mode_t
#endif

#if DEPLOYMENT_TARGET_LINUX
    
#define CF_PRIVATE __attribute__((visibility("hidden")))
#define __weak

#define strtod_l(a,b,locale) strtod(a,b)
#define strtoul_l(a,b,c,locale) strtoul(a,b,c)
#define strtol_l(a,b,c,locale) strtol(a,b,c)
#define strtoll_l(a,b,c,locale) strtoll(a,b,c)
#define strncasecmp_l(a, b, c, d) strncasecmp(a, b, c)

#define fprintf_l(a,locale,b,...) fprintf(a, b, __VA_ARGS__)

#include <pthread.h>

#if TARGET_OS_ANDROID
typedef unsigned long fd_mask;
#endif
    
#if !TARGET_OS_ANDROID && !TARGET_OS_CYGWIN
CF_INLINE size_t
strlcpy(char * dst, const char * src, size_t maxlen) {
    const size_t srclen = strlen(src);
    if (srclen < maxlen) {
        memcpy(dst, src, srclen+1);
    } else if (maxlen != 0) {
        memcpy(dst, src, maxlen-1);
        dst[maxlen-1] = '\0';
    }
    return srclen;
}

CF_INLINE size_t
strlcat(char * dst, const char * src, size_t maxlen) {
    const size_t srclen = strlen(src);
    const size_t dstlen = strnlen(dst, maxlen);
    if (dstlen == maxlen) return maxlen+srclen;
    if (srclen < maxlen-dstlen) {
        memcpy(dst+dstlen, src, srclen+1);
    } else {
        memcpy(dst+dstlen, src, maxlen-dstlen-1);
        dst[maxlen-1] = '\0';
    }
    return dstlen + srclen;
}
#endif

#if !TARGET_OS_CYGWIN
#define issetugid() 0
#endif
    
// Implemented in CFPlatform.c 
bool OSAtomicCompareAndSwapPtr(void *oldp, void *newp, void *volatile *dst);
bool OSAtomicCompareAndSwapLong(long oldl, long newl, long volatile *dst);
bool OSAtomicCompareAndSwapPtrBarrier(void *oldp, void *newp, void *volatile *dst);
bool OSAtomicCompareAndSwap64Barrier( int64_t __oldValue, int64_t __newValue, volatile int64_t *__theValue );
    
int32_t OSAtomicDecrement32Barrier(volatile int32_t *dst);
int32_t OSAtomicIncrement32Barrier(volatile int32_t *dst);
int32_t OSAtomicIncrement32(volatile int32_t *theValue);
int32_t OSAtomicDecrement32(volatile int32_t *theValue);

int32_t OSAtomicAdd32( int32_t theAmount, volatile int32_t *theValue );
int32_t OSAtomicAdd32Barrier( int32_t theAmount, volatile int32_t *theValue );
bool OSAtomicCompareAndSwap32Barrier( int32_t oldValue, int32_t newValue, volatile int32_t *theValue );
    
void OSMemoryBarrier();

#include <malloc.h>
CF_INLINE size_t malloc_size(void *memblock) {
    return malloc_usable_size(memblock);
}

#include <time.h>
CF_INLINE uint64_t mach_absolute_time() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_nsec + (uint64_t)ts.tv_sec * 1000000000UL;
}

#endif
    
#if DEPLOYMENT_TARGET_FREEBSD
#define HAVE_STRUCT_TIMESPEC 1

#define CF_PRIVATE __attribute__((visibility("hidden")))
#define __strong
#define __weak

// Implemented in CFPlatform.c
bool OSAtomicCompareAndSwapPtr(void *oldp, void *newp, void *volatile *dst);
bool OSAtomicCompareAndSwapLong(long oldl, long newl, long volatile *dst);
bool OSAtomicCompareAndSwapPtrBarrier(void *oldp, void *newp, void *volatile *dst);
bool OSAtomicCompareAndSwap64Barrier( int64_t __oldValue, int64_t __newValue, volatile int64_t *__theValue );

int32_t OSAtomicDecrement32Barrier(volatile int32_t *dst);
int32_t OSAtomicIncrement32Barrier(volatile int32_t *dst);
int32_t OSAtomicIncrement32(volatile int32_t *theValue);
int32_t OSAtomicDecrement32(volatile int32_t *theValue);

int32_t OSAtomicAdd32( int32_t theAmount, volatile int32_t *theValue );
int32_t OSAtomicAdd32Barrier( int32_t theAmount, volatile int32_t *theValue );
bool OSAtomicCompareAndSwap32Barrier( int32_t oldValue, int32_t newValue, volatile int32_t *theValue );

void OSMemoryBarrier();

#endif

#if TARGET_OS_CYGWIN
#define HAVE_STRUCT_TIMESPEC 1
#define strncasecmp_l(a, b, c, d) strncasecmp(a, b, c)
#define _NO_BOOL_TYPEDEF
#undef interface
#endif

#if DEPLOYMENT_TARGET_WINDOWS || DEPLOYMENT_TARGET_LINUX
#if !defined(MIN)
#define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif
    
#if !defined(MAX)
#define MAX(A,B)	((A) > (B) ? (A) : (B))
#endif
    
#if !defined(ABS)
#define ABS(A)	((A) < 0 ? (-(A)) : (A))
#endif    
#endif

#if DEPLOYMENT_TARGET_WINDOWS

#define MAXPATHLEN MAX_PATH
#undef MAX_PATH
#undef INVALID_HANDLE_VALUE

// Defined for source compatibility
#define ino_t _ino_t
#define off_t _off_t
#define mode_t uint16_t
        
// This works because things aren't actually exported from the DLL unless they have a __declspec(dllexport) on them... so extern by itself is closest to __private_extern__ on Mac OS
#define CF_PRIVATE extern
    
#define __builtin_expect(P1,P2) P1
    
// These are replacements for POSIX calls on Windows, ensuring that the UTF8 parameters are converted to UTF16 before being passed to Windows
CF_EXPORT int _NS_stat(const char *name, struct _stat *st);
CF_EXPORT int _NS_mkdir(const char *name);
CF_EXPORT int _NS_rmdir(const char *name);
CF_EXPORT int _NS_chmod(const char *name, int mode);
CF_EXPORT int _NS_unlink(const char *name);
CF_EXPORT char *_NS_getcwd(char *dstbuf, size_t size);     // Warning: this doesn't support dstbuf as null even though 'getcwd' does
CF_EXPORT char *_NS_getenv(const char *name);
CF_EXPORT int _NS_rename(const char *oldName, const char *newName);
CF_EXPORT int _NS_open(const char *name, int oflag, int pmode = 0);
CF_EXPORT int _NS_chdir(const char *name);
CF_EXPORT int _NS_mkstemp(char *name, int bufSize);
CF_EXPORT int _NS_access(const char *name, int amode);

#define BOOL WINDOWS_BOOL

#define WIN32_LEAN_AND_MEAN

#ifndef WINVER
#define WINVER  0x0501
#endif
    
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif

// The order of these includes is important
#define FD_SETSIZE 1024
#include <winsock2.h>
#include <windows.h>
#include <pthread.h>

#undef BOOL

#ifndef HAVE_STRUCT_TIMESPEC
#define HAVE_STRUCT_TIMESPEC 1
struct timespec {
        long tv_sec;
        long tv_nsec;
};
#endif /* HAVE_STRUCT_TIMESPEC */

#define __PRETTY_FUNCTION__ __FUNCTION__

#define malloc_default_zone() (void *)0
#define malloc_zone_from_ptr(a) (void *)0
#define malloc_zone_malloc(zone,size) malloc(size)
#define malloc_zone_memalign(zone,align,size) malloc(size)
#define malloc_zone_calloc(zone,count,size) calloc(count,size)
#define bcopy(b1,b2,len) memmove(b2, b1, (size_t)(len))
typedef int malloc_zone_t;
typedef int uid_t;
typedef int gid_t;
#define geteuid() 0
#define getuid() 0
#define getegid() 0

#define scalbn(A, B) _scalb(A, B)

#define fsync(a) _commit(a)
#define malloc_create_zone(a,b) 123
#define malloc_set_zone_name(zone,name)
#define malloc_zone_realloc(zone,ptr,size) realloc(ptr,size)
#define malloc_zone_free(zone,ptr) free(ptr)

// implemented in CFInternal.h
#define OSSpinLockLock(A) __CFLock(A)
#define OSSpinLockUnlock(A) __CFUnlock(A)
    
typedef int32_t OSSpinLock;

#define OS_SPINLOCK_INIT       0

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <malloc.h>

CF_INLINE size_t malloc_size(void *memblock) {
    return _msize(memblock);
}

CF_INLINE uint64_t mach_absolute_time() {
    LARGE_INTEGER count;
    QueryPerformanceCounter(&count);
    // mach_absolute_time is unsigned, but this function returns a signed value.
    return (uint64_t)count.QuadPart;
}

CF_INLINE long long llabs(long long v) {
    if (v < 0) return -v;
    return v;
}

#define strtod_l(a,b,locale) strtod(a,b)
#define strtoul_l(a,b,c,locale) strtoul(a,b,c)
#define strtol_l(a,b,c,locale) strtol(a,b,c)
#define strtoll_l(a,b,c,locale) _strtoi64(a,b,c)
#define strncasecmp(a, b, c) _strnicmp(a, b, c)
#define strncasecmp_l(a, b, c, d) _strnicmp(a, b, c)
#define snprintf _snprintf

#define fprintf_l(a,locale,b,...) fprintf(a, b, __VA_ARGS__)

CF_INLINE size_t
strlcpy(char * dst, const char * src, size_t maxlen) {
    const size_t srclen = strlen(src);
    if (srclen < maxlen) {
        memcpy(dst, src, srclen+1);
    } else if (maxlen != 0) {
        memcpy(dst, src, maxlen-1);
        dst[maxlen-1] = '\0';
    }
    return srclen;
}

CF_INLINE size_t
strlcat(char * dst, const char * src, size_t maxlen) {
    const size_t srclen = strlen(src);
    const size_t dstlen = strnlen(dst, maxlen);
    if (dstlen == maxlen) return maxlen+srclen;
    if (srclen < maxlen-dstlen) {
        memcpy(dst+dstlen, src, srclen+1);
    } else {
        memcpy(dst+dstlen, src, maxlen-dstlen-1);
        dst[maxlen-1] = '\0';
    }
    return dstlen + srclen;
}

#define sleep(x) Sleep(1000*x)

#define issetugid() 0

// CF exports these useful atomic operation functions on Windows
CF_EXPORT bool OSAtomicCompareAndSwapPtr(void *oldp, void *newp, void *volatile *dst);
CF_EXPORT bool OSAtomicCompareAndSwapLong(long oldl, long newl, long volatile *dst);
CF_EXPORT bool OSAtomicCompareAndSwapPtrBarrier(void *oldp, void *newp, void *volatile *dst);

CF_EXPORT int32_t OSAtomicDecrement32Barrier(volatile int32_t *dst);
CF_EXPORT int32_t OSAtomicIncrement32Barrier(volatile int32_t *dst);
CF_EXPORT int32_t OSAtomicIncrement32(volatile int32_t *theValue);
CF_EXPORT int32_t OSAtomicDecrement32(volatile int32_t *theValue);
    
CF_EXPORT int32_t OSAtomicAdd32( int32_t theAmount, volatile int32_t *theValue );
CF_EXPORT int32_t OSAtomicAdd32Barrier( int32_t theAmount, volatile int32_t *theValue );
CF_EXPORT bool OSAtomicCompareAndSwap32Barrier( int32_t oldValue, int32_t newValue, volatile int32_t *theValue );

/*
CF_EXPORT bool OSAtomicCompareAndSwap64( int64_t __oldValue, int64_t __newValue, volatile int64_t *__theValue );
CF_EXPORT bool OSAtomicCompareAndSwap64Barrier( int64_t __oldValue, int64_t __newValue, volatile int64_t *__theValue );
    
CF_EXPORT int64_t OSAtomicAdd64( int64_t __theAmount, volatile int64_t *__theValue );
CF_EXPORT int64_t OSAtomicAdd64Barrier( int64_t __theAmount, volatile int64_t *__theValue );
*/

//#ifndef NTDDI_VERSION
//#define NTDDI_VERSION NTDDI_WINXP
//#endif

#include <io.h>
#include <fcntl.h>
#include <errno.h>
    
#endif

#if !defined(CF_PRIVATE)
#define CF_PRIVATE __attribute__((__visibility__("hidden")))
#endif

#if DEPLOYMENT_TARGET_LINUX || DEPLOYMENT_TARGET_WINDOWS

#include <stdarg.h>

CF_INLINE int flsl( long mask ) {
    int idx = 0;
    while (mask != 0) mask = (unsigned long)mask >> 1, idx++;
    return idx;
}
    
CF_INLINE int popcountll(long long x) {
    int count = 0;
    while (x) {
        count++;
        x &= x - 1; // reset LS1B
    }
    return count;
}

CF_PRIVATE int asprintf(char **ret, const char *format, ...);

#endif

#if DEPLOYMENT_TARGET_WINDOWS && defined(__cplusplus)
} // extern "C"
#endif

#endif // __COREFOUNDATION_PREFIX_H__
