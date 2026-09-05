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
	newbin - xcrun <<- 'EOF'
	#!/usr/bin/env bash
	# Open-source xcrun compatibility shim for LLVM on Linux/Darwin
	set -e

	# Self-locate EPREFIX if not set
	if [[ -z "${EPREFIX}" ]]; then
		SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
		if [[ "$SELF_DIR" == */usr/bin ]]; then
			EPREFIX="${SELF_DIR%/usr/bin}"
		fi
	fi

	SHOW_SDK_PATH=0
	SHOW_SDK_VERSION=0
	SHOW_SDK_PLATFORM_PATH=0
	FIND_TOOL=0
	SDK_NAME=""
	TOOL=""
	TOOL_ARGS=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--show-sdk-path|-show-sdk-path)
				SHOW_SDK_PATH=1
				shift
				;;
			--show-sdk-version|--show-sdk-platform-version|-show-sdk-version|-show-sdk-platform-version)
				SHOW_SDK_VERSION=1
				shift
				;;
			--show-sdk-platform-path|-show-sdk-platform-path)
				SHOW_SDK_PLATFORM_PATH=1
				shift
				;;
			-f|--find|-find)
				FIND_TOOL=1
				TOOL="$2"
				shift 2
				;;
			-s|--sdk|-sdk)
				SDK_NAME="$2"
				shift 2
				;;
			-v|--verbose|-n|--no-cache)
				shift
				;;
			-r|--run)
				shift
				TOOL="$1"
				shift
				TOOL_ARGS=("$@")
				break
				;;
			-*)
				shift
				;;
			*)
				if [[ -z "$TOOL" ]]; then
					TOOL="$1"
					shift
					TOOL_ARGS=("$@")
					break
				fi
				;;
		esac
	done

	resolve_sdkroot() {
		if [[ -n "$SDKROOT" && -d "$SDKROOT" ]]; then
			echo "$SDKROOT"
			return 0
		fi
		local targets=("arm64-apple-darwin" "x86_64-apple-darwin")
		if [[ -n "$CTARGET" ]]; then
			targets=("$CTARGET" "${targets[@]}")
		fi
		for t in "${targets[@]}"; do
			for p in "${EPREFIX}/usr/${t}" "/usr/${t}"; do
				if [[ -n "$p" && -d "$p" ]]; then
					echo "$p"
					return 0
				fi
			done
		done
		echo "/"
	}

	RESOLVED_SDKROOT=$(resolve_sdkroot)

	if [[ $SHOW_SDK_PATH -eq 1 ]]; then
		echo "$RESOLVED_SDKROOT"
		exit 0
	fi

	if [[ $SHOW_SDK_PLATFORM_PATH -eq 1 ]]; then
		echo "$RESOLVED_SDKROOT"
		exit 0
	fi

	if [[ $SHOW_SDK_VERSION -eq 1 ]]; then
		echo "14.0"
		exit 0
	fi

	if [[ -z "$TOOL" ]]; then
		echo "xcrun: error: no tool specified" >&2
		exit 1
	fi

	resolve_tool() {
		local name="$1"
		local target="${CTARGET:-arm64-apple-darwin}"
		case "$name" in
			clang|cc)
				command -v "${target}-clang" 2>/dev/null || \
				command -v clang 2>/dev/null || true
				;;
			clang++|c++)
				command -v "${target}-clang++" 2>/dev/null || \
				command -v clang++ 2>/dev/null || true
				;;
			ld)
				command -v ld64.lld 2>/dev/null || \
				command -v "${target}-ld" 2>/dev/null || \
				command -v ld.lld 2>/dev/null || \
				command -v ld 2>/dev/null || true
				;;
			ar)
				command -v llvm-ar 2>/dev/null || \
				command -v "${target}-ar" 2>/dev/null || \
				command -v ar 2>/dev/null || true
				;;
			ranlib)
				command -v llvm-ranlib 2>/dev/null || \
				command -v "${target}-ranlib" 2>/dev/null || \
				command -v ranlib 2>/dev/null || true
				;;
			libtool)
				command -v llvm-libtool-darwin 2>/dev/null || \
				command -v libtool 2>/dev/null || true
				;;
			install_name_tool)
				command -v llvm-install-name-tool 2>/dev/null || \
				command -v install_name_tool 2>/dev/null || true
				;;
			otool)
				command -v llvm-otool 2>/dev/null || \
				command -v otool 2>/dev/null || true
				;;
			nm)
				command -v llvm-nm 2>/dev/null || \
				command -v nm 2>/dev/null || true
				;;
			lipo)
				command -v llvm-lipo 2>/dev/null || \
				command -v lipo 2>/dev/null || true
				;;
			strip)
				command -v llvm-strip 2>/dev/null || \
				command -v strip 2>/dev/null || true
				;;
			dsymutil)
				command -v dsymutil 2>/dev/null || true
				;;
			tapi)
				command -v tapi 2>/dev/null || \
				command -v apple-libtapi 2>/dev/null || true
				;;
			*)
				if command -v "$name" >/dev/null 2>&1; then
					command -v "$name"
				elif [[ -n "$target" ]] && command -v "${target}-${name}" >/dev/null 2>&1; then
					command -v "${target}-${name}"
				elif command -v "llvm-${name}" >/dev/null 2>&1; then
					command -v "llvm-${name}"
				fi
				;;
		esac
	}

	EXE=$(resolve_tool "$TOOL")
	if [[ -z "$EXE" ]]; then
		echo "xcrun: error: cannot find tool '$TOOL'" >&2
		exit 1
	fi

	if [[ $FIND_TOOL -eq 1 ]]; then
		echo "$EXE"
		exit 0
	fi

	EXTRA_ARGS=()
	if [[ "$TOOL" == "clang" || "$TOOL" == "clang++" || "$TOOL" == "cc" || "$TOOL" == "c++" ]]; then
		HAS_TARGET=0
		HAS_ISYSROOT=0
		HAS_FUSE_LD=0
		for arg in "${TOOL_ARGS[@]}"; do
			if [[ "$arg" == -target* || "$arg" == --target* ]]; then
				HAS_TARGET=1
			fi
			if [[ "$arg" == -isysroot* || "$arg" == --sysroot* ]]; then
				HAS_ISYSROOT=1
			fi
			if [[ "$arg" == -fuse-ld* ]]; then
				HAS_FUSE_LD=1
			fi
		done
		if [[ $HAS_TARGET -eq 0 ]]; then
			default_triple="arm64-apple-macos14.0"
			if [[ "${CTARGET}" == x86_64* ]]; then
				default_triple="x86_64-apple-macos14.0"
			fi
			EXTRA_ARGS+=("-target" "${default_triple}")
		fi
		if [[ $HAS_ISYSROOT -eq 0 && "$RESOLVED_SDKROOT" != "/" ]]; then
			EXTRA_ARGS+=("--sysroot" "$RESOLVED_SDKROOT")
		fi
		if [[ $HAS_FUSE_LD -eq 0 ]]; then
			EXTRA_ARGS+=("-fuse-ld=lld")
		fi
	fi

	exec "$EXE" "${EXTRA_ARGS[@]}" "${TOOL_ARGS[@]}"
	EOF

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
