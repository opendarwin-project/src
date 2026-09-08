# Copyright 2026 Gentoo Authors
# Distributed under the terms of the MIT License

EAPI=8

DESCRIPTION="Xcode toolchain compatibility wrappers (xcrun, xcselect, toolchain layout) for LLVM"
HOMEPAGE="https://github.com/apple-oss-distributions"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~arm64-macos ~x64-macos"

RDEPEND="
	llvm-core/clang
	llvm-core/lld
	sys-devel/xcbuild
"

src_install() {
	dobin "${FILESDIR}"/sw_vers
	dobin "${FILESDIR}"/codesign
	dosym codesign /usr/bin/codesign_allocate
	# Do not clobber procps sysctl (usr-merged /usr/bin == /usr/sbin).
	exeinto /usr/libexec/darwin
	newexe "${FILESDIR}"/sysctl sysctl

	# Target aliases pointing to xcbuild's real xcrun binary
	dosym xcrun /usr/bin/arm64-apple-darwin-xcrun
	dosym xcrun /usr/bin/x86_64-apple-darwin-xcrun
}
