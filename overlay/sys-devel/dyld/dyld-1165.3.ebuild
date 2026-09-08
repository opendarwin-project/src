# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8

inherit crossdev

DESCRIPTION="Apple's dynamic linker (dyld) and libdyld runtime"
HOMEPAGE="https://github.com/apple-oss-distributions/dyld"
SRC_URI="https://github.com/apple-oss-distributions/dyld/archive/refs/tags/dyld-${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/dyld-dyld-${PV}"

LICENSE="APSL-2"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

BDEPEND="
	sys-devel/xcbuild
	sys-devel/xcode-toolchain-wrappers
"
DEPEND="
	sys-libs/libsystem
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/dyld-1165.3-linux.patch"
)

src_compile() {
	local target_arch="arm64"
	if [[ ${CTARGET} == x86_64* ]]; then
		target_arch="x86_64"
	fi

	local myxcodebuildargs=(
		-project dyld.xcodeproj
		-target dyld
		-target libdyld.dylib
		-configuration Release
		ARCHS="${target_arch}"
		VALID_ARCHS="${target_arch}"
		SYMROOT="${T}/sym"
		OBJROOT="${T}/obj"
		build
	)

	xcodebuild "${myxcodebuildargs[@]}" || die "dyld xcodebuild failed"
}

src_install() {
	into /usr
	local build_dir="${T}/sym/Release"

	if [[ -f "${build_dir}/dyld" ]]; then
		exeinto /usr/lib
		doexe "${build_dir}/dyld"
	fi

	if [[ -f "${build_dir}/libdyld.dylib" ]]; then
		insinto /usr/lib/system
		doins "${build_dir}/libdyld.dylib"
		dosym system/libdyld.dylib /usr/lib/libdyld.dylib
	fi

	# Install public dyld headers
	insinto /usr/include
	doins -r include/*
}
