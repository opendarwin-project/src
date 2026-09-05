#ifndef _HOST_COMPAT_H_
#define _HOST_COMPAT_H_

#include <sys/types.h>
#include <stdint.h>
#include <stdbool.h>

#ifndef __private_extern__
#define __private_extern__ __attribute__((visibility("hidden")))
#endif

typedef unsigned int u_int;

#endif
