# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8

DESCRIPTION="XNU kernel (RELEASE ARM64 VMAPPLE) from apple-oss-distributions"
HOMEPAGE="https://github.com/apple-oss-distributions/xnu"
AVAILABILITY_PV="157.2"
LIBDISPATCH_PV="1477.100.9"
SRC_URI="
	https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${PV}.tar.gz -> xnu-${PV}.tar.gz
	https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-${AVAILABILITY_PV}.tar.gz -> AvailabilityVersions-${AVAILABILITY_PV}.tar.gz
	https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-${LIBDISPATCH_PV}.tar.gz -> libdispatch-${LIBDISPATCH_PV}.tar.gz
"

S="${WORKDIR}/xnu-xnu-${PV}"
AVAILABILITY_S="${WORKDIR}/AvailabilityVersions-AvailabilityVersions-${AVAILABILITY_PV}"
LIBDISPATCH_S="${WORKDIR}/libdispatch-libdispatch-${LIBDISPATCH_PV}"
LICENSE="APSL-2 Apache-2.0"
SLOT="0"
KEYWORDS="~arm64-macos"
IUSE=""

BDEPEND="
	sys-devel/bootstrap-cmds
	sys-devel/xcode-toolchain-wrappers
	dev-util/unifdef
	dev-build/cmake
"

PATCHES=(
	"${FILESDIR}/xnu-10063.141.1-linux-build.patch"
	"${FILESDIR}/xnu-10063.141.1-mockfs.patch"
	"${FILESDIR}/xnu-10063.141.1-clang-compat.patch"
	"${FILESDIR}/xnu-10063.141.1-trustcache.patch"
	"${FILESDIR}/xnu-10063.141.1-iokit.patch"
	"${FILESDIR}/xnu-10063.141.1-entitlements.patch"
	"${FILESDIR}/xnu-10063.141.1-setup-mach-headers.patch"
)

src_prepare() {
	default

	# OSKext/os_log include <os/firehose_buffer_private.h> from libdispatch SPI.
	# The header is gated on OS_FIREHOSE_SPI; kernel consumers require it.
	cp "${LIBDISPATCH_S}/os/firehose_buffer_private.h" "${S}/libkern/os/" || die
	sed -i 's/^#if OS_FIREHOSE_SPI$/#ifndef OS_FIREHOSE_SPI\n#define OS_FIREHOSE_SPI 1\n#endif\n#if OS_FIREHOSE_SPI/' \
		"${S}/libkern/os/firehose_buffer_private.h" || die

	local dk="${S}/iokit/DriverKit"
	mkdir -p "${dk}/crypto" || die
	ln -sf ../IOKit/IOTypes.h "${dk}/IOTypes.h" || die
	ln -sf ../IOKit/IOReturn.h "${dk}/IOReturn.h" || die
	ln -sf ../IOKit/IORPC.h "${dk}/IORPC.h" || die
	ln -sf ../IOKit/IOKitKeys.h "${dk}/IOKitKeys.h" || die
	ln -sf ../IOKit/IOKernelReportStructs.h "${dk}/IOKernelReportStructs.h" || die
	ln -sf ../IOKit/IOReportTypes.h "${dk}/IOReportTypes.h" || die
	ln -sf ../../osfmk/kern/macro_help.h "${dk}/macro_help.h" || die
	local h
	for h in bounded_ptr.h bounded_array.h bounded_array_ref.h bounded_ptr_fwd.h \
		OSBoundedArray.h OSBoundedArrayRef.h OSBoundedPtr.h OSBoundedPtrFwd.h safe_allocation.h; do
		ln -sf "../../libkern/libkern/c++/${h}" "${dk}/${h}" || die
	done
	for h in md5.h sha1.h sha2.h aes.h; do
		ln -sf "../../../libkern/libkern/crypto/${h}" "${dk}/crypto/${h}" || die
	done
}

src_compile() {
	local -x PATH="/usr/libexec/darwin:/usr/lib/llvm/${LLVM_SLOT:-22}/bin:/usr/libexec:${EPREFIX}/usr/bin:/usr/local/bin:${PATH}"

	local clang_bin
	clang_bin="$(command -v clang || true)"
	[[ -n ${clang_bin} ]] || die "clang not found"

	local -x MIGCC="${clang_bin}"
	local -x MIGCOM
	MIGCOM="$(command -v migcom || true)"
	[[ -n ${MIGCOM} ]] || MIGCOM="/usr/libexec/migcom"
	export MIGCC MIGCOM

	local darwin_sysroot="/usr/arm64-apple-darwin"
	[[ -d ${darwin_sysroot}/usr/include ]] || die "Darwin sysroot headers missing at ${darwin_sysroot}/usr/include; merge sys-libs/libsystem first"

	local sdk="${WORKDIR}/sdk"
	mkdir -p "${sdk}/usr/local/libexec" "${sdk}/usr/local/lib/kernel" "${sdk}/usr" \
		"${sdk}/usr/local/include/kernel/os" || die
	ln -sfn "${darwin_sysroot}/usr/include" "${sdk}/usr/include" || die
	ln -sfn "${darwin_sysroot}/usr/lib" "${sdk}/usr/lib" || die
	# availability.pl is a Python driver; installhdrs looks under SDKROOT.
	cp -a "${AVAILABILITY_S}/availability.pl" "${AVAILABILITY_S}/availability" \
		"${AVAILABILITY_S}/availability.dsl" "${AVAILABILITY_S}/templates" \
		"${sdk}/usr/local/libexec/" || die
	# Kernel <os/firehose_buffer_private.h> includes resolve via
	# INCFLAGS_SDK = -I$(SDKROOT)/usr/local/include/kernel (MakeInc.def).
	cp "${S}/libkern/os/firehose_buffer_private.h" \
		"${sdk}/usr/local/include/kernel/os/" || die

	# HOST_CC must be a single path: SETUP tools are Linux ELF.
	# Kernel CC/CXX must go through xcrun (portage exports host CC/CXX).
	# VMAPPLE is arm64, not arm64e; without this MakeInc rewrites arm64 -> arm64e.
	emake \
		CC="xcrun -sdk ${sdk} clang" \
		CXX="xcrun -sdk ${sdk} clang++" \
		SDKROOT="${sdk}" \
		HOST_SDKROOT="/" \
		HOST_CC="${clang_bin}" \
		ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG=arm64 \
		TARGET_CONFIGS="RELEASE ARM64 VMAPPLE" \
		BUILD_WERROR=0 \
		DO_CTFMERGE=0 \
		RC_DARWIN_KERNEL_VERSION="23.0.0" \
		MEMORY_SIZE=17179869184 \
		SYSCTL_HW_PHYSICALCPU=$(nproc) SYSCTL_HW_LOGICALCPU=$(nproc) \
		KERNEL_BUILDS_IN_PARALLEL=1 \
		HOST_CODESIGN=true HOST_CODESIGN_ALLOCATE=true \
		OBJROOT="${S}/BUILD/obj" SYMROOT="${S}/BUILD/sym" DSTROOT="${S}/BUILD/dst"
}

src_install() {
	insinto /usr/lib/opendarwin
	local img
	img="$(find "${S}/BUILD/sym" \( -name 'kernel' -o -name 'kernel.unstripped*' -o -name 'mach.vmapple' \) | head -n1 || true)"
	[[ -n ${img} ]] || die "no kernel image under BUILD/sym"
	newins "${img}" xnu.RELEASE_ARM64_VMAPPLE
}
