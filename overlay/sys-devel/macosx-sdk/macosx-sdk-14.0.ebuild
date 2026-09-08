# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8

DESCRIPTION="Xcode-shaped DEVELOPER_DIR (Platforms/Toolchains) layout for xcbuild"
HOMEPAGE="https://github.com/facebookarchive/xcbuild"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~arm64-macos ~x64-macos"

# The four tool families xcbuild's spec/toolchain layer actually shells out
# to when compiling and linking a Darwin .xcodeproj (clang for compiles, the
# LLVM Darwin binutils for postprocessing). Anything host-side; this package
# never touches a per-target sysroot at build time, only at symlink-target
# names it never dereferences here (see src_install).
RDEPEND="
	llvm-core/clang
	llvm-core/lld
	llvm-core/llvm
"

# `xcbuild::xcsdk` (Libraries/xcsdk/Sources/{Manager,Platform,SDK/Target,
# SDK/Toolchain}.cpp) discovers everything below by walking a real
# filesystem tree rooted at $DEVELOPER_DIR:
#
#   $DEVELOPER_DIR/Platforms/*.platform/Info.plist
#   $DEVELOPER_DIR/Platforms/*.platform/Developer/SDKs/*.sdk/{SDKSettings,Info}.plist
#   $DEVELOPER_DIR/Toolchains/*.xctoolchain/{ToolchainInfo,Info}.plist
#
# never a resource baked into the xcbuild binary itself - so a real,
# on-disk tree is the only way to make `-sdk macosx -toolchain default`
# resolve at all. `DEVELOPER_DIR` itself must point at `${EPREFIX}/usr`
# (xcsdk::Environment::DeveloperRoot reads it verbatim, with no EPREFIX
# awareness of its own); consumers invoking xcbuild set that explicitly,
# the same way this overlay's other cross packages export MIGCC/PATH/etc.
# rather than relying on ambient environment.
src_install() {
	# xcbuild's own spec loader (pbxspec::Manager::DefaultDomains) resolves
	# "Library/Xcode/Specifications" directly under DEVELOPER_DIR, and
	# sys-devel/xcbuild's own CMAKE_INSTALL_PREFIX="${EPREFIX}/" lands its
	# specs at "${EPREFIX}/Library/..." (not under usr/) to match that -
	# same layout as real Xcode.app/Contents/Developer, where Platforms/,
	# Toolchains/, and Library/ are DEVELOPER_DIR's direct children and
	# only usr/bin/xcodebuild itself is nested under usr/. So DEVELOPER_DIR
	# must be this package's own EPREFIX root, and Platforms/Toolchains
	# land there too, not under usr/.
	local plat_dir="/Platforms/MacOSX.platform"
	local sdk_name="MacOSX14.0.sdk"
	local sdk_dir="${plat_dir}/Developer/SDKs/${sdk_name}"
	local tc_dir="/Toolchains/XcodeDefault.xctoolchain"

	insinto "${plat_dir}"
	cat <<-EOF > "${T}/platform-info.plist"
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Identifier</key>
		<string>com.apple.platform.macosx</string>
		<key>Name</key>
		<string>macosx</string>
		<key>Type</key>
		<string>Platform</string>
		<key>Version</key>
		<string>1</string>
		<key>FamilyIdentifier</key>
		<string>com.apple.platform.macosx</string>
		<key>FamilyName</key>
		<string>macOS</string>
		<key>MinimumSDKVersion</key>
		<string>14.0</string>
		<key>IsDeploymentPlatform</key>
		<true/>
	</dict>
	</plist>
	EOF
	newins "${T}/platform-info.plist" Info.plist

	# Everything a compiled Darwin object needs to link against: the real
	# target sysroot this overlay's `sys-libs/libsystem` merges into, as a
	# *sibling* self-hosted EPREFIX (DARWIN_SYSROOT, set in make.conf) -
	# not `/usr/${CTARGET}` under this same EPREFIX. Vanilla portage's
	# rootless model (see darwin-root/make.conf) needs each self-hosted
	# EPREFIX to have exactly one CHOST/profile, so the host-arch toolchain
	# packages here (xcbuild, this package) and the arm64-apple-darwin
	# target content (libsystem) cannot share one EPREFIX. A plain
	# symlink, not a copy - `dosym` never dereferences its target, so this
	# resolves correctly whichever order libsystem and this package merge.
	local darwin_sysroot="${DARWIN_SYSROOT:?DARWIN_SYSROOT must point at the arm64-apple-darwin sysroot prefix}"
	insinto "${sdk_dir}"
	cat <<-EOF > "${T}/sdk-settings.plist"
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
<dict>
	<key>CanonicalName</key>
	<string>macosx14.0</string>
	<key>Aliases</key>
	<array>
		<string>macosx</string>
		<string>macosx.internal</string>
		<string>macosx14.0</string>
		<string>macosx14.0.internal</string>
	</array>
	<key>DisplayName</key>
	<string>macOS 14.0</string>
	<key>Version</key>
	<string>14.0</string>
	<key>IsBaseSDK</key>
	<true/>
	<key>DefaultDeploymentTarget</key>
	<string>14.0</string>
	<key>MaximumDeploymentTarget</key>
	<string>14.0.99</string>
	<key>DefaultProperties</key>
	<dict>
		<key>PLATFORM_NAME</key>
		<string>macosx</string>
		<key>ARCHS</key>
		<string>arm64</string>
		<key>VALID_ARCHS</key>
		<string>arm64 x86_64</string>
	</dict>
</dict>
</plist>
EOF
	newins "${T}/sdk-settings.plist" SDKSettings.plist
	dosym "${darwin_sysroot%/}/usr/include" "${sdk_dir}/usr/include"
	dosym "${darwin_sysroot%/}/usr/lib" "${sdk_dir}/usr/lib"
	dosym "${sdk_name}" "${plat_dir}/Developer/SDKs/MacOSX.sdk"
	dosym "${sdk_name}" "${plat_dir}/Developer/SDKs/MacOSX.internal.sdk"
	dosym "${sdk_name}" "${plat_dir}/Developer/SDKs/MacOSX14.0.internal.sdk"
	# The default toolchain: real LLVM binaries this overlay already
	# builds/wraps for the host, exposed under the exact tool names
	# xcbuild's spec files invoke (Tools/clang.xcspec's CC, Tools/
	# ld.xcspec's LD, etc - never routed back through `xcrun`, which
	# decides -target/-isysroot itself and would double them up).
	insinto "${tc_dir}"
	cat <<-EOF > "${T}/toolchain-info.plist"
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Identifier</key>
		<string>com.apple.dt.toolchain.XcodeDefault</string>
		<key>DisplayName</key>
		<string>Open Darwin LLVM Toolchain</string>
		<key>Version</key>
		<string>1.0</string>
	</dict>
	</plist>
	EOF
	newins "${T}/toolchain-info.plist" ToolchainInfo.plist

	local tool real
	for tool in clang:clang clang++:clang++ ld:ld64.lld ar:llvm-ar \
		ranlib:llvm-ranlib nm:llvm-nm strip:llvm-strip lipo:llvm-lipo \
		otool:llvm-otool install_name_tool:llvm-install-name-tool \
		libtool:llvm-libtool-darwin dsymutil:dsymutil; do
		real="$(command -v "${tool#*:}" || true)"
		[[ -n ${real} ]] || continue
		dosym "${real}" "${tc_dir}/usr/bin/${tool%%:*}"
	done
}
