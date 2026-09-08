# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8
inherit cmake git-r3

DESCRIPTION="Reimplementation of Apple's Xcode build tools (xcodebuild) for Linux"
HOMEPAGE="https://github.com/opendarwin-project/xcbuild"
EGIT_REPO_URI="https://github.com/opendarwin-project/xcbuild.git"
EGIT_COMMIT="6780f29767fc3d647e3a9fa93905cf62a3e144a0"
EGIT_SUBMODULES=( ThirdParty/googletest ThirdParty/linenoise )

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

RDEPEND="
	media-libs/libpng:=
	sys-libs/zlib
	dev-libs/libxml2
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

# Patches (no-werror, cmake minimum, specifications, #include handling)
# are integrated upstream in the opendarwin-project fork.

src_configure() {
	# Upstream's -Wall -Werror (2016-era warning set) does not build clean
	# under a modern GCC/Clang — the patch above drops -Werror; the two
	# -include flags paper over a handful of missing <cstdint>/<cstdlib>
	# includes upstream never needed against its original (older) libstdc++.
	# This is a build-time-only host tool (drives xcodebuild-compatible
	# builds of other Darwin packages' .xcodeproj files), not part of any
	# target sysroot, so no CTARGET-awareness is needed here.
	local -x CXXFLAGS="${CXXFLAGS} -include cstdint -include cstdlib"
	local mycmakeargs=(
		# The project's own CMakeLists uses relative install()
		# DESTINATION paths ("usr/bin", "Library/Xcode/Specifications",
		# …) that assume an empty install prefix — cmake.eclass's default
		# "${EPREFIX}/usr" would double it to ".../usr/usr/bin". Verified
		# directly: a raw `cmake -DCMAKE_INSTALL_PREFIX=/` + `make
		# install DESTDIR=...` lands binaries at usr/bin and the pbxbuild
		# tool specs at Library/Xcode/Specifications, exactly matching
		# where xcbuild's own spec loader looks for a system-wide
		# extension point.
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/"
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	# Only the driver binaries matter to consumers (Libc/dyld/etc. builds
	# invoking `xcbuild -project … -target … build`); the bundled test
	# binaries and internal libraries are build-time-only.
	dosym xcbuild /usr/bin/xcodebuild
}
