# Copyright 2026 Gentoo Authors
# Distributed under the terms of the MIT License

EAPI=8

inherit crossdev

DESCRIPTION="Open source Darwin libSystem runtime and headers for cross-compilation"
HOMEPAGE="https://github.com/apple-oss-distributions/libsystem"
SRC_URI="
	https://github.com/apple-oss-distributions/libsystem/archive/refs/tags/Libsystem-${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/apple-oss-distributions/darwin-headers/releases/download/14.0/darwin-headers-14.0.tar.xz
"
S="${WORKDIR}"

LICENSE="APSL-2 MIT"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

src_compile() {
	# Determine target arch
	local target_arch="arm64"
	if [[ ${CTARGET} == x86_64* ]]; then
		target_arch="x86_64"
	fi

	# Generate TAPI v4 text stub for libSystem
	cat <<-EOF > "${T}/libSystem.B.tbd"
	--- !tapi-tbd
	tbd-version: 4
	targets: [ arm64-macos, x86_64-macos ]
	install-name: /usr/lib/libSystem.B.dylib
	current-version: ${PV}
	compatibility-version: 1
	exports:
	  - targets: [ arm64-macos, x86_64-macos ]
	    symbols:
	      - dyld_stub_binder
	      - ___error
	      - ___stack_chk_fail
	      - ___stack_chk_guard
	      - _exit
	      - __exit
	      - _abort
	      - _getpid
	      - _getppid
	      - _getuid
	      - _geteuid
	      - _getgid
	      - _getegid
	      - _read
	      - _write
	      - _open
	      - _close
	      - _unlink
	      - _chdir
	      - _fchdir
	      - _chmod
	      - _chown
	      - _dup
	      - _pipe
	      - _fcntl
	      - _fsync
	      - _mkdir
	      - _rmdir
	      - _rename
	      - _access
	      - _mmap
	      - _munmap
	      - _malloc
	      - _free
	      - _calloc
	      - _realloc
	      - _strdup
	      - _memcpy
	      - _memset
	      - _memmove
	      - _memcmp
	      - _strlen
	      - _strcmp
	      - _strncmp
	      - _strcpy
	      - _strncpy
	      - _strcat
	      - _strncat
	      - _strchr
	      - _strrchr
	      - _strstr
	      - _puts
	      - _printf
	      - _sprintf
	      - _snprintf
	      - ___snprintf_chk
	      - ___sprintf_chk
	      - _pthread_mutex_init
	      - _pthread_mutex_lock
	      - _pthread_mutex_unlock
	      - _pthread_mutex_destroy
	      - _pthread_once
	...
	EOF

	# Compile actual Mach-O libSystem.B.dylib shared library
	local clang_bin="clang"
	if command -v "${CTARGET}-clang" >/dev/null 2>&1; then
		clang_bin="${CTARGET}-clang"
	fi

	"${clang_bin}" -target "${CTARGET:-arm64-apple-darwin}" \
		-fno-stack-protector -ffreestanding -dynamiclib \
		-install_name /usr/lib/libSystem.B.dylib \
		-compatibility_version 1.0 -current_version ${PV}.0 \
		-fuse-ld=lld -nostdlib \
		-o "${T}/libSystem.B.dylib" \
		"${FILESDIR}/libsystem_runtime.c" || die "failed to compile libSystem.B.dylib"
}

src_install() {
	local sysroot="/"
	if is_crosspkg && target_is_not_host; then
		sysroot="/usr/${CTARGET}"
	fi

	into "${sysroot}/usr"
	insinto "${sysroot}/usr/lib"
	doins "${T}/libSystem.B.tbd"
	doins "${T}/libSystem.B.dylib"

	dosym libSystem.B.dylib "${sysroot}/usr/lib/libSystem.dylib"
	dosym libSystem.B.tbd "${sysroot}/usr/lib/libSystem.tbd"
	dosym libSystem.B.dylib "${sysroot}/usr/lib/libc.dylib"
	dosym libSystem.B.dylib "${sysroot}/usr/lib/libm.dylib"
	dosym libSystem.B.dylib "${sysroot}/usr/lib/libpthread.dylib"
	dosym libSystem.B.dylib "${sysroot}/usr/lib/libdl.dylib"

	# Install Darwin C and kernel SDK headers
	if [[ -d "${WORKDIR}/include" ]]; then
		insinto "${sysroot}/usr"
		doins -r "${WORKDIR}/include"
	fi

	# Basic headers from upstream Libsystem source
	if [[ -f "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h" ]]; then
		insinto "${sysroot}/usr/include"
		doins "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h"
	fi
}
