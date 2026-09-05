# Copyright 2026 Gentoo Authors
# Distributed under the terms of the MIT License

EAPI=8

inherit crossdev

DESCRIPTION="Open source Darwin libSystem runtime and headers for cross-compilation"
HOMEPAGE="https://github.com/apple-oss-distributions/libsystem"
XNU_PV="10063.141.1"
LIBC_PV="1592.100.35"
LIBPTHREAD_PV="519.120.4"
LIBPLATFORM_PV="316.100.10"
LIBMALLOC_PV="521.120.7"
AVAILABILITY_PV="157.2"
OPENBSM_PV="21"
CARBONHEADERS_PV="18.1"

SRC_URI="
	https://github.com/apple-oss-distributions/libsystem/archive/refs/tags/Libsystem-${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${XNU_PV}.tar.gz -> xnu-${XNU_PV}.tar.gz
	https://github.com/apple-oss-distributions/Libc/archive/refs/tags/Libc-${LIBC_PV}.tar.gz -> Libc-${LIBC_PV}.tar.gz
	https://github.com/apple-oss-distributions/libpthread/archive/refs/tags/libpthread-${LIBPTHREAD_PV}.tar.gz -> libpthread-${LIBPTHREAD_PV}.tar.gz
	https://github.com/apple-oss-distributions/libplatform/archive/refs/tags/libplatform-${LIBPLATFORM_PV}.tar.gz -> libplatform-${LIBPLATFORM_PV}.tar.gz
	https://github.com/apple-oss-distributions/libmalloc/archive/refs/tags/libmalloc-${LIBMALLOC_PV}.tar.gz -> libmalloc-${LIBMALLOC_PV}.tar.gz
	https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-${AVAILABILITY_PV}.tar.gz -> AvailabilityVersions-${AVAILABILITY_PV}.tar.gz
	https://github.com/apple-oss-distributions/OpenBSM/archive/refs/tags/OpenBSM-${OPENBSM_PV}.tar.gz -> OpenBSM-${OPENBSM_PV}.tar.gz
	https://github.com/apple-oss-distributions/CarbonHeaders/archive/refs/tags/CarbonHeaders-${CARBONHEADERS_PV}.tar.gz -> CarbonHeaders-${CARBONHEADERS_PV}.tar.gz
"
S="${WORKDIR}"

LICENSE="APSL-2 MIT"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

BDEPEND="
	dev-build/cmake
	dev-build/ninja
"

XNU_S="${WORKDIR}/xnu-xnu-${XNU_PV}"
LIBC_S="${WORKDIR}/Libc-Libc-${LIBC_PV}"
LIBPTHREAD_S="${WORKDIR}/libpthread-libpthread-${LIBPTHREAD_PV}"
LIBPLATFORM_S="${WORKDIR}/libplatform-libplatform-${LIBPLATFORM_PV}"
LIBMALLOC_S="${WORKDIR}/libmalloc-libmalloc-${LIBMALLOC_PV}"
AVAILABILITY_S="${WORKDIR}/AvailabilityVersions-AvailabilityVersions-${AVAILABILITY_PV}"
OPENBSM_S="${WORKDIR}/OpenBSM-OpenBSM-${OPENBSM_PV}"
CARBONHEADERS_S="${WORKDIR}/CarbonHeaders-CarbonHeaders-${CARBONHEADERS_PV}"

src_prepare() {
	default

	# libmalloc's private _malloc_type.h uses the unpublished internal
	# __SPI_AVAILABLE spelling; alias it to the real published macro.
	cd "${LIBMALLOC_S}" || die
	eapply "${FILESDIR}/libmalloc-spi-availability-compat.patch"
	cd "${WORKDIR}" || die

	# xnu's DriverKit Makefile lists a handful of headers that live in
	# other xnu subtrees (IOKit, libkern/c++, crypto); the make-based build
	# expects a prior Xcode "Copy Headers" phase to stage them, which we
	# replace with real symlinks to the same upstream files.
	cd "${XNU_S}" || die
	eapply "${FILESDIR}/xnu-10063.141.1-driverkit-headers.patch"
	ln -sf ../IOKit/IOTypes.h iokit/DriverKit/IOTypes.h || die
	ln -sf ../IOKit/IOReturn.h iokit/DriverKit/IOReturn.h || die
	ln -sf ../IOKit/IORPC.h iokit/DriverKit/IORPC.h || die
	ln -sf ../IOKit/IOKitKeys.h iokit/DriverKit/IOKitKeys.h || die
	ln -sf ../IOKit/IOKernelReportStructs.h iokit/DriverKit/IOKernelReportStructs.h || die
	ln -sf ../IOKit/IOReportTypes.h iokit/DriverKit/IOReportTypes.h || die
	ln -sf ../../osfmk/kern/macro_help.h iokit/DriverKit/macro_help.h || die
	local h
	for h in bounded_ptr.h bounded_array.h bounded_array_ref.h bounded_ptr_fwd.h \
		OSBoundedArray.h OSBoundedArrayRef.h OSBoundedPtr.h OSBoundedPtrFwd.h safe_allocation.h; do
		ln -sf "../../libkern/libkern/c++/${h}" "iokit/DriverKit/${h}" || die
	done
	for h in md5.h sha1.h sha2.h aes.h; do
		ln -sf "../../../libkern/libkern/crypto/${h}" "iokit/DriverKit/crypto/${h}" || die
	done
	cd "${WORKDIR}" || die

	# CarbonHeaders-18.1 predates arm64 Macs: give TargetConditionals.h a
	# real arm64 branch, mirroring the existing __arm__/__x86_64__ ones.
	sed -i \
		-e '/#elif defined(__arm__)/i\
     #elif defined(__arm64__) || defined(__aarch64__) \
        #define TARGET_CPU_PPC          0\
        #define TARGET_CPU_PPC64        0\
        #define TARGET_CPU_68K          0\
        #define TARGET_CPU_X86          0\
        #define TARGET_CPU_X86_64       0\
        #define TARGET_CPU_ARM          0\
        #define TARGET_CPU_ARM64        1\
        #define TARGET_CPU_MIPS         0\
        #define TARGET_CPU_SPARC        0\
        #define TARGET_CPU_ALPHA        0\
        #define TARGET_RT_MAC_CFM       0\
        #define TARGET_RT_MAC_MACHO     1\
        #define TARGET_RT_LITTLE_ENDIAN 1\
        #define TARGET_RT_BIG_ENDIAN    0\
        #define TARGET_RT_64_BIT        1' \
		-e 's/@CONFIG_EMBEDDED@/0/' \
		-e 's/@CONFIG_IPHONE@/0/' \
		-e 's/@CONFIG_IPHONE_SIMULATOR@/0/' \
		"${CARBONHEADERS_S}/TargetConditionals.h" || die
}

src_compile() {
	# Public Availability*.h / os_availability.h are code-generated, not
	# hand-written, from the real AvailabilityVersions build tooling.
	cd "${AVAILABILITY_S}" || die
	emake \
		SRCROOT="${AVAILABILITY_S}" \
		OBJROOT="${AVAILABILITY_S}/obj" \
		SYMROOT="${AVAILABILITY_S}/sym" \
		DSTROOT="${AVAILABILITY_S}/dst" \
		cmake
	cmake --build "${AVAILABILITY_S}/obj" || die "AvailabilityVersions build failed"
	cmake --install "${AVAILABILITY_S}/obj" || die "AvailabilityVersions install failed"
	cd "${WORKDIR}" || die

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

	# Assemble the open-source Darwin SDK headers directly from upstream
	# apple-oss-distributions sources (never a bundled/proprietary SDK).
	local hdr="${ED}/${sysroot}/usr/include"
	_install() { # src... dest_subdir
		local dest="$1"; shift
		mkdir -p "${hdr}/${dest}" || die
		cp -r "$@" "${hdr}/${dest}/" || die
	}

	# Real xnu "make installhdrs" run (the same recipe apple-oss-distributions'
	# own build uses) rather than hand-picking individual bsd/osfmk/libkern
	# headers file-by-file; it drives xnu's own generator scripts
	# (makesyscalls.sh, make_symbol_aliasing.sh, make_posix_availability.sh)
	# and resolves the real cross-directory header set for us.
	local xnu_dst="${WORKDIR}/xnu-hdrs-dst"
	local rc_darwin_kernel_version="23.0.0"
	# make_symbol_aliasing.sh looks for availability.pl (+ its data file) under
	# ${SDKROOT}/usr/local/libexec, matching where it lives on a real Apple SDK.
	mkdir -p "${xnu_dst}/usr/local/libexec" || die
	cp "${AVAILABILITY_S}"/availability.pl "${AVAILABILITY_S}"/availability "${xnu_dst}/usr/local/libexec/" || die
	chmod +x "${xnu_dst}/usr/local/libexec/availability.pl" || die
	emake -C "${XNU_S}" installhdrs \
		SDKROOT="${xnu_dst}" \
		TARGET_CONFIGS="RELEASE ARM64 VMAPPLE" \
		BUILD_WERROR=0 \
		RC_DARWIN_KERNEL_VERSION="${rc_darwin_kernel_version}" \
		MEMORY_SIZE=17179869184 SYSCTL_HW_PHYSICALCPU=$(nproc) SYSCTL_HW_LOGICALCPU=$(nproc) \
		KERNEL_BUILDS_IN_PARALLEL=1 \
		MIGCC="$(xcrun -find clang)" HOST_CODESIGN=true HOST_CODESIGN_ALLOCATE=true \
		OBJROOT="${XNU_S}/BUILD/obj" SYMROOT="${XNU_S}/BUILD/sym" DSTROOT="${xnu_dst}" \
		|| die "xnu make installhdrs failed"
	cp -r "${xnu_dst}"/usr/include/* "${hdr}/" || die
	[[ -d ${xnu_dst}/usr/local/include ]] && cp -r "${xnu_dst}"/usr/local/include/* "${hdr}/" || die

	cp "${XNU_S}"/libsyscall/wrappers/spawn/spawn.h "${hdr}/" || die

	[[ -d ${LIBPLATFORM_S}/include ]] && cp -r "${LIBPLATFORM_S}"/include/* "${hdr}/" || die
	[[ -d ${LIBPTHREAD_S}/include ]] && cp -r "${LIBPTHREAD_S}"/include/* "${hdr}/" || die
	cp -r "${LIBC_S}"/include/* "${hdr}/" || die
	# Libc's include/sys/cdefs.h is an #include_next wrapper expecting the
	# real one from xnu bsd/sys/cdefs.h underneath; restore it after Libc.
	cp "${XNU_S}"/bsd/sys/cdefs.h "${hdr}/sys/" || die

	for subdir in gen stdlib stdio string sys; do
		[[ -d ${LIBC_S}/${subdir} ]] && cp "${LIBC_S}/${subdir}"/*.h "${hdr}/" 2>/dev/null
	done
	cp "${LIBC_S}/locale/xlocale_private.h" "${hdr}/" || die

	# libmalloc public + private (patched) headers.
	cp -r "${LIBMALLOC_S}"/include/malloc "${hdr}/" || die

	# CarbonHeaders compatibility macros (TargetConditionals, MacTypes, etc).
	cp "${CARBONHEADERS_S}"/*.h "${hdr}/" || die
	# Generated public Availability.h/AvailabilityInternal.h supersede
	# CarbonHeaders' committed copies.
	cp -r "${AVAILABILITY_S}"/dst/usr/include/* "${hdr}/" || die

	_install bsm "${OPENBSM_S}"/openbsm/bsm/*.h

	# Our own compat shim aliasing internal->public availability macros.
	cp "${FILESDIR}/spi-availability-compat.h" "${hdr}/" || die

	# Basic headers from upstream Libsystem source itself.
	if [[ -f "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h" ]]; then
		cp "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h" "${hdr}/" || die
	fi
}
