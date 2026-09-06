# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8
inherit git-r3

DESCRIPTION="tinted-software U-Boot with bootxnu, for qemu virt Darwin bring-up"
HOMEPAGE="https://github.com/tinted-software/u-boot"
EGIT_REPO_URI="https://github.com/tinted-software/u-boot.git"
EGIT_BRANCH="main"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

BDEPEND="
	llvm-core/clang
	llvm-core/lld
	llvm-core/llvm
"

src_configure() {
	emake qemu_arm64_defconfig
	# CMD_BOOTXNU defaults to y in this fork; keep it explicit.
	if [[ -x scripts/config ]]; then
		scripts/config --enable CMD_BOOTXNU || die
	fi
}

src_compile() {
	emake LLVM=1 -j$(makeopts_jobs)
}

src_install() {
	insinto /usr/share/u-boot-xnu
	newins u-boot.bin u-boot.bin
	dodoc README
}
