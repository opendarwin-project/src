# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8

DESCRIPTION="Freestanding OpenDarwin PID 1 for mockfs RAMDisk bring-up"
HOMEPAGE="https://github.com/apple-oss-distributions"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~arm64-macos ~x64-macos"

src_compile() {
	local clang_bin
	clang_bin="$(command -v "${CTARGET:-arm64-apple-darwin}-clang" || true)"
	[[ -n ${clang_bin} ]] || clang_bin="$(command -v clang || true)"
	[[ -n ${clang_bin} ]] || die "clang not found"
	"${clang_bin}" \
		-target "${CTARGET:-arm64-apple-darwin}" \
		-ffreestanding -fno-builtin -mstrict-align -mgeneral-regs-only \
		-fno-stack-protector -fno-PIC -O2 \
		-fuse-ld=lld -nostdlib -static -Wl,-e,_start \
		"${FILESDIR}"/od_init.c -o od_init.macho || die
}

src_install() {
	insinto /usr/lib/opendarwin
	doins od_init.macho
}
