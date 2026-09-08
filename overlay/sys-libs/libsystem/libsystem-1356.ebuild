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
# Real Libsystem.xcodeproj is link-only glue: its own `requiredlibs` names
# ~15 dylibs it links against, each from a *separate* apple-oss-distributions
# repo. These five are open-source and fetchable:
DISPATCH_PV="1542.100.32"
DYLD_PV="1378"
UNWIND_PV="201"
REMOVEFILE_PV="85.100.6"
COPYFILE_PV="240"
NOTIFY_PV="348.120.4"
COMMONCRYPTO_PV="600035"
CCTOOLS_PV="1035.1.102"
CONFIGD_PV="1405.120.5"
# NOT fetchable / not wired in yet, tracked here rather than silently
# missing from the requiredlibs closure:
#   - xpc: libxpc has never been open-sourced by Apple - no public repo
#     exists at all. A from-source `system_notify`/xpc component is
#     impossible; Libsystem's real xpc symbols must stay stubbed.
#   - corecrypto: apple/corecrypto (different org - not apple-oss-
#     distributions) has no version tags and ships under a custom
#     "Other"/NOASSERTION license, not APSL-2 like the rest of this
#     ebuild's sources - needs an explicit LICENSE/license-review decision
#     before vendoring, not a same-pattern SRC_URI add.
#   - compiler_rt: this requiredlibs entry means LLVM's compiler-rt
#     builtins, not an apple-oss-distributions checkout - satisfied by the
#     host LLVM toolchain's own runtime build, not a source fetch here.

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
	https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-${DISPATCH_PV}.tar.gz -> libdispatch-${DISPATCH_PV}.tar.gz
	https://github.com/apple-oss-distributions/dyld/archive/refs/tags/dyld-${DYLD_PV}.tar.gz -> dyld-${DYLD_PV}.tar.gz
	https://github.com/apple-oss-distributions/libunwind/archive/refs/tags/libunwind-${UNWIND_PV}.tar.gz -> libunwind-${UNWIND_PV}.tar.gz
	https://github.com/apple-oss-distributions/removefile/archive/refs/tags/removefile-${REMOVEFILE_PV}.tar.gz -> removefile-${REMOVEFILE_PV}.tar.gz
	https://github.com/apple-oss-distributions/copyfile/archive/refs/tags/copyfile-${COPYFILE_PV}.tar.gz -> copyfile-${COPYFILE_PV}.tar.gz
	https://github.com/apple-oss-distributions/Libnotify/archive/refs/tags/Libnotify-${NOTIFY_PV}.tar.gz -> Libnotify-${NOTIFY_PV}.tar.gz
	https://github.com/apple-oss-distributions/CommonCrypto/archive/refs/tags/CommonCrypto-${COMMONCRYPTO_PV}.tar.gz -> CommonCrypto-${COMMONCRYPTO_PV}.tar.gz
	https://github.com/apple-oss-distributions/cctools/archive/refs/tags/cctools-${CCTOOLS_PV}.tar.gz -> cctools-${CCTOOLS_PV}.tar.gz
	https://github.com/apple-oss-distributions/configd/archive/refs/tags/configd-${CONFIGD_PV}.tar.gz -> configd-${CONFIGD_PV}.tar.gz
"
S="${WORKDIR}"

LICENSE="APSL-2 MIT"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

BDEPEND="
	dev-build/cmake
	dev-build/ninja
	dev-lang/python:*
	dev-util/unifdef
	sys-devel/bison
	sys-devel/flex
	sys-devel/bootstrap-cmds
	sys-devel/iig-tools
	sys-devel/xcode-toolchain-wrappers
	sys-devel/xcbuild
"

XNU_S="${WORKDIR}/xnu-xnu-${XNU_PV}"
LIBC_S="${WORKDIR}/Libc-Libc-${LIBC_PV}"
LIBPTHREAD_S="${WORKDIR}/libpthread-libpthread-${LIBPTHREAD_PV}"
LIBPLATFORM_S="${WORKDIR}/libplatform-libplatform-${LIBPLATFORM_PV}"
LIBMALLOC_S="${WORKDIR}/libmalloc-libmalloc-${LIBMALLOC_PV}"
AVAILABILITY_S="${WORKDIR}/AvailabilityVersions-AvailabilityVersions-${AVAILABILITY_PV}"
OPENBSM_S="${WORKDIR}/OpenBSM-OpenBSM-${OPENBSM_PV}"
CARBONHEADERS_S="${WORKDIR}/CarbonHeaders-CarbonHeaders-${CARBONHEADERS_PV}"
DISPATCH_S="${WORKDIR}/libdispatch-libdispatch-${DISPATCH_PV}"
DYLD_S="${WORKDIR}/dyld-dyld-${DYLD_PV}"
UNWIND_S="${WORKDIR}/libunwind-libunwind-${UNWIND_PV}"
REMOVEFILE_S="${WORKDIR}/removefile-removefile-${REMOVEFILE_PV}"
COPYFILE_S="${WORKDIR}/copyfile-copyfile-${COPYFILE_PV}"
NOTIFY_S="${WORKDIR}/Libnotify-Libnotify-${NOTIFY_PV}"
COMMONCRYPTO_S="${WORKDIR}/CommonCrypto-CommonCrypto-${COMMONCRYPTO_PV}"
CCTOOLS_S="${WORKDIR}/cctools-cctools-${CCTOOLS_PV}"
CONFIGD_S="${WORKDIR}/configd-configd-${CONFIGD_PV}"

src_prepare() {
	default

	# xnu's build assumes a macOS host: absolute /usr/bin/xcrun, /usr/sbin/sysctl,
	# macOS-only host-tool APIs, a csh doconf, and an Xcode "Copy Headers" phase
	# that stages DriverKit's headers from sibling subtrees. Replace that staging
	# step with symlinks to the same upstream files.
	cd "${XNU_S}" || die
	eapply "${FILESDIR}/xnu-10063.141.1-linux-build.patch"
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

	cat <<-EOF >> "${CARBONHEADERS_S}/TargetConditionals.h"
	#ifndef TARGET_OS_OSX
	#define TARGET_OS_OSX 1
	#endif
	#ifndef TARGET_OS_IOS
	#define TARGET_OS_IOS 0
	#endif
	#ifndef TARGET_OS_TV
	#define TARGET_OS_TV 0
	#endif
	#ifndef TARGET_OS_WATCH
	#define TARGET_OS_WATCH 0
	#endif
	#ifndef TARGET_OS_BRIDGE
	#define TARGET_OS_BRIDGE 0
	#endif
	#ifndef TARGET_OS_MACCATALYST
	#define TARGET_OS_MACCATALYST 0
	#endif
	#ifndef TARGET_OS_SIMULATOR
	#define TARGET_OS_SIMULATOR 0
	#endif
	#ifndef TARGET_OS_DRIVERKIT
	#define TARGET_OS_DRIVERKIT 0
	#endif
	#ifndef TARGET_OS_EXCLAVECORE
	#define TARGET_OS_EXCLAVECORE 0
	#endif
	#ifndef TARGET_OS_EXCLAVEKIT
	#define TARGET_OS_EXCLAVEKIT 0
	#endif
	#ifndef TARGET_OS_VISION
	#define TARGET_OS_VISION 0
	#endif
	EOF
}

src_compile() {
	# Public Availability*.h / os_availability.h are code-generated, not
	# hand-written, from the real AvailabilityVersions build tooling.
	cd "${AVAILABILITY_S}" || die
	cmake -S "${AVAILABILITY_S}" -B "${AVAILABILITY_S}/obj" \
		-DSRCROOT="${AVAILABILITY_S}" \
		-DOBJROOT="${AVAILABILITY_S}/obj" \
		-DSYMROOT="${AVAILABILITY_S}/sym" \
		-DCMAKE_INSTALL_PREFIX="${AVAILABILITY_S}/dst/usr" \
		-DDSTROOT="${AVAILABILITY_S}/dst" \
		-DDRIVERKIT=0 -DSYSTEM_PREFIX="" -DCONFIG_EXCLAVEKIT=0 \
		-DCONFIG_EXCLAVECORE=0 -DCONFIG_KERNELKIT=0 \
		-DINSTALL_KERNEL_HEADERS="1" -DAV_VERSION="157.2" || die "AvailabilityVersions cmake configure failed"
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
	local clang_bin
	if command -v "${CTARGET}-clang" >/dev/null 2>&1; then
		clang_bin="${CTARGET}-clang"
	elif command -v xcrun >/dev/null 2>&1; then
		clang_bin="$(xcrun -find clang)"
	else
		clang_bin="$(command -v clang || true)"
	fi
	[[ -n ${clang_bin} && -x ${clang_bin} ]] || die "clang not found (need xcrun or clang on PATH)"

	"${clang_bin}" -target "${CTARGET:-arm64-apple-darwin}" \
		-fno-stack-protector -ffreestanding -dynamiclib \
		-install_name /usr/lib/libSystem.B.dylib \
		-compatibility_version 1.0 -current_version ${PV}.0 \
		-fuse-ld=lld -nostdlib \
		-o "${T}/libSystem.B.dylib" \
		"${FILESDIR}/libsystem_runtime.c" || die "failed to compile libSystem.B.dylib"
}

src_install() {
	# Plain /usr destinations: this package is merged with the per-target
	# sysroot as ROOT (crossdev's model), so placement under
	# /usr/${CTARGET} comes from ROOT, not from the install paths.
	into /usr
	insinto /usr/lib
	doins "${T}/libSystem.B.tbd"
	doins "${T}/libSystem.B.dylib"

	dosym libSystem.B.dylib /usr/lib/libSystem.dylib
	dosym libSystem.B.tbd /usr/lib/libSystem.tbd
	dosym libSystem.B.dylib /usr/lib/libc.dylib
	dosym libSystem.B.dylib /usr/lib/libm.dylib
	dosym libSystem.B.dylib /usr/lib/libpthread.dylib
	dosym libSystem.B.dylib /usr/lib/libdl.dylib

	# Assemble the open-source Darwin SDK headers directly from upstream
	# apple-oss-distributions sources (never a bundled/proprietary SDK).
	local hdr="${ED}/usr/include"
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
	# availability.pl is a Python driver; it needs the sibling "availability"
	# module, availability.dsl, and templates/ next to it.
	cp "${AVAILABILITY_S}"/availability.pl "${AVAILABILITY_S}"/availability \
		"${AVAILABILITY_S}"/availability.dsl "${xnu_dst}/usr/local/libexec/" || die
	cp -a "${AVAILABILITY_S}"/templates "${xnu_dst}/usr/local/libexec/" || die
	chmod +x "${xnu_dst}/usr/local/libexec/availability.pl" || die

	# Darwin sysctl shim + slotted clang live outside /usr/bin on this stage3.
	# Export MIGCC/MIGCOM via the environment (not make command-line): GNU make
	# does not export command-line vars, and MakeInc.cmd only `export`s MIGCC
	# when origin is undefined.
	local -x PATH="/usr/libexec/darwin:/usr/lib/llvm/${LLVM_SLOT:-22}/bin:/usr/libexec:${EPREFIX}/usr/bin:${EPREFIX}/usr/local/libexec:/usr/local/bin:${PATH}"
	local -x MIGCC MIGCOM
	MIGCC="$(command -v clang || true)"
	[[ -n ${MIGCC} ]] || MIGCC="$(xcrun -find clang)" || die "clang not found"
	MIGCOM="$(command -v migcom || true)"
	[[ -n ${MIGCOM} ]] || MIGCOM="/usr/libexec/migcom"
	[[ -x ${MIGCOM} ]] || die "migcom not found at ${MIGCOM}"
	export MIGCC MIGCOM
	emake -C "${XNU_S}" installhdrs \
		PLATFORM="MacOSX" \
		SDKROOT="macosx14.0" \
		HOST_SDKROOT_RESOLVED="/" \
		HOST_CC="$(tc-getBUILD_CC)" \
		HOST_CODESIGN="true" \
		HOST_BISON="bison" \
		HOST_FLEX="flex" \
		HOST_GM4="m4" \
		TARGET_CONFIGS="RELEASE ARM64 VMAPPLE" \
		BUILD_WERROR=0 \
		RC_DARWIN_KERNEL_VERSION="${rc_darwin_kernel_version}" \
		MEMORY_SIZE=17179869184 SYSCTL_HW_PHYSICALCPU=1 SYSCTL_HW_LOGICALCPU=1 \
		KERNEL_BUILDS_IN_PARALLEL=1 \
		HOST_CODESIGN_ALLOCATE=true \
		OBJROOT="${XNU_S}/BUILD/obj" SYMROOT="${XNU_S}/BUILD/sym" DSTROOT="${xnu_dst}" \
		|| die "xnu make installhdrs failed"
	mkdir -p "${hdr}" || die
	cp -rf "${xnu_dst}"/usr/include/* "${hdr}/" || die
	[[ -d ${xnu_dst}/usr/local/include ]] && cp -rf "${xnu_dst}"/usr/local/include/* "${hdr}/" || die

	# Stage macOS Frameworks
	if [[ -d "${xnu_dst}/System/Library/Frameworks" ]]; then
		mkdir -p "${ED}/System/Library/Frameworks" || die
		cp -rf "${xnu_dst}/System/Library/Frameworks"/* "${ED}/System/Library/Frameworks/" || die
		local fw ver
		for fw in "${ED}"/System/Library/Frameworks/*.framework; do
			[[ -d "${fw}" ]] || continue
			ver="A"
			[[ -d "${fw}/Versions/B" ]] && ver="B"
			[[ -d "${fw}/Versions/Current" ]] || ln -sf "${ver}" "${fw}/Versions/Current"
			[[ -d "${fw}/PrivateHeaders" ]] || [[ -d "${fw}/Versions/${ver}/PrivateHeaders" ]] && ln -sf "Versions/${ver}/PrivateHeaders" "${fw}/PrivateHeaders"
			[[ -d "${fw}/Headers" ]] || [[ -d "${fw}/Versions/${ver}/Headers" ]] && ln -sf "Versions/${ver}/Headers" "${fw}/Headers"
			[[ -d "${fw}/Headers" ]] || [[ -d "${fw}/Versions/${ver}/PrivateHeaders" ]] && ln -sf "Versions/${ver}/PrivateHeaders" "${fw}/Headers"
		done
	fi
	# Userland libsyscall headers that xnu installhdrs does not stage:
	# unistd.h includes <gethostuuid.h>, and <mach/mach.h> is the
	# libsyscall umbrella (osfmk/mach/mach.h is the in-kernel copy).
	cp "${XNU_S}"/libsyscall/wrappers/gethostuuid.h "${hdr}/" || die
	cp "${XNU_S}"/libsyscall/wrappers/spawn/spawn.h "${hdr}/" || die
	mkdir -p "${hdr}/libproc" || die
	cp "${XNU_S}"/libsyscall/wrappers/libproc/libproc.h "${hdr}/libproc/" || die
	cp "${XNU_S}"/libsyscall/mach/mach/*.h "${hdr}/mach/" || die

	# User MIG headers (clock.h, mach_port.h, ...) are produced by
	# libsyscall's mach_install_mig.sh, not by kernel installhdrs
	# (osfmk/mach INSTALL_MI_GEN_LIST is empty upstream).
	local mig_out="${WORKDIR}/libsyscall-mig"
	local -x SRCROOT="${XNU_S}/libsyscall"
	local -x OBJROOT="${WORKDIR}/libsyscall-obj"
	local -x BUILT_PRODUCTS_DIR="${mig_out}"
	local -x SDKROOT="macosx14.0"
	local -x ARCHS="arm64"
	local -x PLATFORM_NAME="macosx"
	mkdir -p "${OBJROOT}" "${mig_out}" || die
	bash "${XNU_S}/libsyscall/xcodescripts/mach_install_mig.sh" \
		|| die "libsyscall mach_install_mig.sh failed"
	cp -rf "${mig_out}/mig_hdr/include/"* "${hdr}/" || die

	# libplatform public and private headers
	[[ -d ${LIBPLATFORM_S}/include ]] && cp -rf "${LIBPLATFORM_S}"/include/* "${hdr}/" || die
	[[ -d ${LIBPLATFORM_S}/private ]] && cp -rf "${LIBPLATFORM_S}"/private/* "${hdr}/" || die

	# libpthread public and private headers
	[[ -d ${LIBPTHREAD_S}/include ]] && cp -rf "${LIBPTHREAD_S}"/include/* "${hdr}/" || die
	[[ -d ${LIBPTHREAD_S}/private ]] && cp -rf "${LIBPTHREAD_S}"/private/* "${hdr}/" || die
	# libpthread's install-symlinks.sh: historical names at usr/include/*.h
	ln -sf pthread/pthread.h "${hdr}/pthread.h" || die
	ln -sf pthread/pthread_impl.h "${hdr}/pthread_impl.h" || die
	ln -sf pthread/pthread_spis.h "${hdr}/pthread_spis.h" || die
	ln -sf pthread/sched.h "${hdr}/sched.h" || die
	cp -rf "${LIBC_S}"/include/* "${hdr}/" || die
	# Restore libpthread's real qos.h which Libc's wrapper includes via include_next
	[[ -f ${LIBPTHREAD_S}/include/pthread/qos.h ]] && cp -f "${LIBPTHREAD_S}/include/pthread/qos.h" "${hdr}/pthread/qos.h"
	[[ -f ${LIBC_S}/include/NetBSD/utmpx.h ]] && cp -f "${LIBC_S}/include/NetBSD/utmpx.h" "${hdr}/"
	[[ -f ${LIBC_S}/include/FreeBSD/nl_types.h ]] && cp -f "${LIBC_S}/include/FreeBSD/nl_types.h" "${hdr}/"
	# Libc ships an #include_next sys/cdefs.h for its own build. The SDK
	# header is the one installhdrs already unifdef'd into xnu_dst; copying
	# the raw xnu source here would drop XNU_PLATFORM_MacOSX and leave
	# write() aliased to write$UNIX2003 on arm64.
	cp "${xnu_dst}"/usr/include/sys/cdefs.h "${hdr}/sys/" || die
	# installhdrs leaves the XNU_PLATFORM_* lattice intact; a real
	# MacOSX SDK unifdef's this. Do the same so arm64 userland sees
	# __DARWIN_ONLY_UNIX_CONFORMANCE=1 (plain write(), not write$UNIX2003).
	unifdef -m -t -DXNU_PLATFORM_MacOSX -UKERNEL "${hdr}/sys/cdefs.h"
	[[ $? -le 1 ]] || die "unifdef sys/cdefs.h failed"

	for subdir in gen stdlib stdio string sys; do
		[[ -d ${LIBC_S}/${subdir} ]] && cp "${LIBC_S}/${subdir}"/*.h "${hdr}/" 2>/dev/null
	done
	cp "${LIBC_S}/locale/xlocale_private.h" "${hdr}/" || die

	# libmalloc public + private (patched) headers.
	# libmalloc public + private headers
	cp -rf "${LIBMALLOC_S}"/include/malloc "${hdr}/" || die
	[[ -d ${LIBMALLOC_S}/private ]] && cp -rf "${LIBMALLOC_S}"/private/* "${hdr}/" || die

	# cctools mach-o headers (getsect.h, dyld.h, etc)
	if [[ -d "${CCTOOLS_S}/include/mach-o" ]]; then
		mkdir -p "${hdr}/mach-o" || die
		cp -rf "${CCTOOLS_S}/include/mach-o"/* "${hdr}/mach-o/" || die
	fi

	# dyld headers (dlfcn.h, mach-o/dyld.h, etc)
	if [[ -d "${DYLD_S}/include" ]]; then
		cp -rf "${DYLD_S}/include"/* "${hdr}/" || die
	fi

	# libdispatch headers (dispatch/*.h, os/*.h)
	if [[ -d "${DISPATCH_S}" ]]; then
		mkdir -p "${hdr}/dispatch" "${hdr}/os" || die
		[[ -d "${DISPATCH_S}/dispatch" ]] && cp -rf "${DISPATCH_S}/dispatch"/*.h "${hdr}/dispatch/" || die
		[[ -d "${DISPATCH_S}/os" ]] && cp -rf "${DISPATCH_S}/os"/*.h "${hdr}/os/" || die
	fi

	# xnu EXTERNAL_HEADERS (architecture/byte_order.h, AssertMacros.h, etc)
	if [[ -d "${XNU_S}/EXTERNAL_HEADERS" ]]; then
		[[ -d "${XNU_S}/EXTERNAL_HEADERS/architecture" ]] && cp -rf "${XNU_S}/EXTERNAL_HEADERS/architecture" "${hdr}/" || die
		for h in AssertMacros.h ptrauth.h ptrcheck.h; do
			[[ -f "${XNU_S}/EXTERNAL_HEADERS/${h}" ]] && cp -f "${XNU_S}/EXTERNAL_HEADERS/${h}" "${hdr}/" || true
		done
	fi

	# CarbonHeaders compatibility macros (TargetConditionals, MacTypes, etc).
	cp -f "${CARBONHEADERS_S}"/*.h "${hdr}/" || die
	# Generated public Availability.h/AvailabilityInternal.h supersede
	# CarbonHeaders' committed copies.
	cp -rf "${AVAILABILITY_S}"/dst/usr/include/* "${hdr}/" || die

	_install bsm "${OPENBSM_S}"/openbsm/bsm/*.h

	# Basic headers from upstream Libsystem source itself.
	if [[ -f "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h" ]]; then
		cp "${WORKDIR}/libsystem-Libsystem-${PV}/alloc_once_private.h" "${hdr}/" || die
	fi
}
