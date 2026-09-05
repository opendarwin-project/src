/* SPDX-License-Identifier: MIT
 *
 * Apple only publishes the single-underscore `API_AVAILABLE`/`SPI_AVAILABLE`
 * family in the open-sourced os/availability.h; the double-underscore
 * `__API_AVAILABLE`/`__SPI_AVAILABLE` spelling used internally (e.g. by
 * libmalloc's private headers) comes from an AvailabilityInternal.h Apple has
 * never open-sourced. This aliases the internal spelling to the real public
 * macros so genuinely open-source headers that use it still compile.
 */
#ifndef DARWIN_HEADERS_SPI_AVAILABILITY_COMPAT_H
#define DARWIN_HEADERS_SPI_AVAILABILITY_COMPAT_H

#include <os/availability.h>

#ifndef __API_AVAILABLE
#define __API_AVAILABLE(...) API_AVAILABLE(__VA_ARGS__)
#endif
#ifndef __SPI_AVAILABLE
#define __SPI_AVAILABLE(...) SPI_AVAILABLE(__VA_ARGS__)
#endif
#ifndef __API_DEPRECATED
#define __API_DEPRECATED(...)
#endif
#ifndef __API_UNAVAILABLE
#define __API_UNAVAILABLE(...)
#endif

#endif
