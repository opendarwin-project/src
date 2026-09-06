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
"

src_install() {
	dobin "${FILESDIR}"/sw_vers
	dobin "${FILESDIR}"/codesign
	dosym codesign /usr/bin/codesign_allocate
	# plutil shim: xnu MakeInc.cmd hardcodes PLUTIL=/usr/bin/plutil for
	# symbolsets.plist linting/conversion (build_symbol_set_plists target).
	dobin "${FILESDIR}"/plutil
	# Do not clobber procps sysctl (usr-merged /usr/bin == /usr/sbin).
	exeinto /usr/libexec/darwin
	newexe "${FILESDIR}"/sysctl sysctl

	# xnu MakeInc.cmd sed-extracts PLATFORM from this path.
	dodir /usr/Platforms/MacOSX.platform

	dobin "${FILESDIR}"/xcrun

	dosym xcrun /usr/bin/xcode-select
	dosym xcrun /usr/bin/arm64-apple-darwin-xcrun
	dosym xcrun /usr/bin/x86_64-apple-darwin-xcrun

	# Xcode toolchain layout directory structure
	local tc_dir="/usr/lib/llvm/xcode-toolchain"
	dodir "${tc_dir}/usr/bin"
	dosym ../../../../bin/xcrun "${tc_dir}/usr/bin/xcrun"

	insinto "${tc_dir}"
	cat <<- 'EOF' > "${ED}/${tc_dir}/ToolchainInfo.plist"
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Identifier</key>
		<string>org.llvm.open-darwin</string>
		<key>DisplayName</key>
		<string>Open Darwin LLVM Toolchain</string>
		<key>Version</key>
		<string>1.0</string>
	</dict>
	</plist>
	EOF
}
