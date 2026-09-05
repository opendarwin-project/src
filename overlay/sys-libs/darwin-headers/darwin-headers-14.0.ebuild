# Copyright 2026 Gentoo Authors
# Distributed under the terms of the MIT License

EAPI=8

inherit crossdev

DESCRIPTION="Open-source Darwin/XNU userland SDK headers assembled from apple-oss-distributions"
HOMEPAGE="https://github.com/apple-oss-distributions"

XNU_PV="10063.141.1"
LIBC_PV="1592.100.35"
LIBPTHREAD_PV="519.120.4"
LIBPLATFORM_PV="316.100.10"
LIBMALLOC_PV="521.120.7"
ARCHITECTURE_PV="282"
AVAILABILITY_PV="157.2"
OPENBSM_PV="21"
CARBONHEADERS_PV="18.1"

SRC_URI="
	https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${XNU_PV}.tar.gz -> xnu-${XNU_PV}.tar.gz
	https://github.com/apple-oss-distributions/Libc/archive/refs/tags/Libc-${LIBC_PV}.tar.gz -> Libc-${LIBC_PV}.tar.gz
	https://github.com/apple-oss-distributions/libpthread/archive/refs/tags/libpthread-${LIBPTHREAD_PV}.tar.gz -> libpthread-${LIBPTHREAD_PV}.tar.gz
	https://github.com/apple-oss-distributions/libplatform/archive/refs/tags/libplatform-${LIBPLATFORM_PV}.tar.gz -> libplatform-${LIBPLATFORM_PV}.tar.gz
	https://github.com/apple-oss-distributions/libmalloc/archive/refs/tags/libmalloc-${LIBMALLOC_PV}.tar.gz -> libmalloc-${LIBMALLOC_PV}.tar.gz
	https://github.com/apple-oss-distributions/architecture/archive/refs/tags/architecture-${ARCHITECTURE_PV}.tar.gz -> architecture-${ARCHITECTURE_PV}.tar.gz
	https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-${AVAILABILITY_PV}.tar.gz -> AvailabilityVersions-${AVAILABILITY_PV}.tar.gz
	https://github.com/apple-oss-distributions/OpenBSM/archive/refs/tags/OpenBSM-${OPENBSM_PV}.tar.gz -> OpenBSM-${OPENBSM_PV}.tar.gz
	https://github.com/apple-oss-distributions/CarbonHeaders/archive/refs/tags/CarbonHeaders-${CARBONHEADERS_PV}.tar.gz -> CarbonHeaders-${CARBONHEADERS_PV}.tar.gz
"
S="${WORKDIR}"

# All constituent projects are APSL-2 (Apple) except CarbonHeaders (APSL-2)
# and this ebuild's own glue, which is MIT.
LICENSE="APSL-2 MIT"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

BDEPEND="
	dev-build/cmake
	dev-util/ninja
"

XNU_S="${WORKDIR}/xnu-xnu-${XNU_PV}"
LIBC_S="${WORKDIR}/Libc-Libc-${LIBC_PV}"
LIBPTHREAD_S="${WORKDIR}/libpthread-libpthread-${LIBPTHREAD_PV}"
LIBPLATFORM_S="${WORKDIR}/libplatform-libplatform-${LIBPLATFORM_PV}"
LIBMALLOC_S="${WORKDIR}/libmalloc-libmalloc-${LIBMALLOC_PV}"
ARCHITECTURE_S="${WORKDIR}/architecture-architecture-${ARCHITECTURE_PV}"
AVAILABILITY_S="${WORKDIR}/AvailabilityVersions-AvailabilityVersions-${AVAILABILITY_PV}"
OPENBSM_S="${WORKDIR}/OpenBSM-OpenBSM-${OPENBSM_PV}"
CARBONHEADERS_S="${WORKDIR}/CarbonHeaders-CarbonHeaders-${CARBONHEADERS_PV}"

src_prepare() {
	# libmalloc's private _malloc_type.h uses the unpublished internal
	# __SPI_AVAILABLE spelling; alias it to the real published macro.
	cd "${LIBMALLOC_S}" || die
	eapply "${FILESDIR}/libmalloc-spi-availability-compat.patch"
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
	cd "${AVAILABILITY_S}" || die
	emake \
		SRCROOT="${AVAILABILITY_S}" \
		OBJROOT="${AVAILABILITY_S}/obj" \
		SYMROOT="${AVAILABILITY_S}/sym" \
		DSTROOT="${AVAILABILITY_S}/dst" \
		cmake
	cmake --build "${AVAILABILITY_S}/obj" || die "AvailabilityVersions build failed"
}

src_install() {
	local hdr="${ED}/usr/include"
	if is_crosspkg && target_is_not_host; then
		hdr="${ED}/usr/${CTARGET}/usr/include"
	fi

	_install() { # src... dest_subdir
		local dest="$1"; shift
		mkdir -p "${hdr}/${dest}" || die
		cp -r "$@" "${hdr}/${dest}/" || die
	}

	# architecture(3) CPU-specific ABI headers.
	_install architecture "${ARCHITECTURE_S}"/*.h
	local arch_dir="arm"
	[[ ${CTARGET} == x86_64* ]] && arch_dir="i386"
	if [[ -d "${ARCHITECTURE_S}/${arch_dir}" ]]; then
		_install "architecture/${arch_dir}" "${ARCHITECTURE_S}/${arch_dir}"/*.h
		_install machine "${ARCHITECTURE_S}/${arch_dir}"/*.h
	fi

	# XNU: BSD, Mach, libkern, and EXTERNAL_HEADERS export sets.
	_install sys "${XNU_S}"/bsd/sys/*.h
	[[ -d ${XNU_S}/bsd/sys/_types ]] && _install sys/_types "${XNU_S}"/bsd/sys/_types/*.h
	for netdir in net netinet netinet6; do
		[[ -d ${XNU_S}/bsd/${netdir} ]] && _install "${netdir}" "${XNU_S}/bsd/${netdir}"/*.h
	done
	_install mach "${XNU_S}"/osfmk/mach/*.h
	if [[ -d ${XNU_S}/osfmk/mach/${arch_dir} ]]; then
		_install "mach/${arch_dir}" "${XNU_S}/osfmk/mach/${arch_dir}"/*.h
		_install mach/machine "${XNU_S}/osfmk/mach/${arch_dir}"/*.h
	fi
	[[ -d ${XNU_S}/osfmk/mach/machine ]] && \
		cp -r "${XNU_S}"/osfmk/mach/machine/*.h "${hdr}/mach/machine/" 2>/dev/null
	[[ -d ${XNU_S}/osfmk/device ]] && _install device "${XNU_S}"/osfmk/device/*.h
	[[ -d ${XNU_S}/osfmk/kern ]] && _install kern "${XNU_S}"/osfmk/kern/*.h
	if [[ -d ${XNU_S}/libkern/libkern ]]; then
		_install libkern "${XNU_S}"/libkern/libkern/*.h
		[[ -d ${XNU_S}/libkern/libkern/${arch_dir} ]] && \
			_install "libkern/${arch_dir}" "${XNU_S}/libkern/libkern/${arch_dir}"/*.h
	fi
	[[ -d ${XNU_S}/EXTERNAL_HEADERS ]] && cp -r "${XNU_S}"/EXTERNAL_HEADERS/*.h "${hdr}/" 2>/dev/null
	cp "${XNU_S}"/libsyscall/wrappers/spawn/spawn.h "${hdr}/" || die

	# sys/syscall.h is generated, not hand-written, from the real
	# syscalls.master via XNU's own makesyscalls.sh.
	( cd "${XNU_S}/bsd/kern" && sh makesyscalls.sh syscalls.master header ) || die
	cp "${XNU_S}/bsd/kern/syscall.h" "${hdr}/sys/" || die

	# libplatform / libpthread / Libc userland headers.
	[[ -d ${LIBPLATFORM_S}/include ]] && cp -r "${LIBPLATFORM_S}"/include/* "${hdr}/" || die
	[[ -d ${LIBPTHREAD_S}/include ]] && cp -r "${LIBPTHREAD_S}"/include/* "${hdr}/" || die
	cp -r "${LIBC_S}"/include/* "${hdr}/" || die
	for subdir in gen stdlib stdio string sys; do
		[[ -d ${LIBC_S}/${subdir} ]] && cp "${LIBC_S}/${subdir}"/*.h "${hdr}/" 2>/dev/null
	done
	cp "${LIBC_S}/locale/xlocale_private.h" "${hdr}/" || die

	# libmalloc public + private (patched) headers.
	cp -r "${LIBMALLOC_S}"/include/malloc "${hdr}/" || die

	# CarbonHeaders compatibility macros (Availability*, TargetConditionals,
	# MacTypes, ConditionalMacros, Endian, MacErrors, AssertMacros).
	cp "${CARBONHEADERS_S}"/*.h "${hdr}/" || die
	# The generated public Availability.h/AvailabilityInternal.h from
	# AvailabilityVersions supersede CarbonHeaders' committed copies.
	cp "${AVAILABILITY_S}"/obj/Availability.h "${hdr}/" || die
	cp "${AVAILABILITY_S}"/obj/AvailabilityInternal.h "${hdr}/" || die
	find "${AVAILABILITY_S}/obj" -name 'os_availability.h' -exec cp {} "${hdr}/../os/" \; 2>/dev/null

	# OpenBSM audit headers.
	_install bsm "${OPENBSM_S}"/bsm/*.h

	# Our own compat shim aliasing internal->public availability macros.
	cp "${FILESDIR}/spi-availability-compat.h" "${hdr}/" || die
}
