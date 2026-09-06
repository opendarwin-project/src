# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

COMMIT="28010c688caab7eb5400b9c98faa5b1e538e0108"

DESCRIPTION="PureDarwin iig-tools implementation for I/O Kit Interface Generator"
HOMEPAGE="https://github.com/PureDarwin/iig-tools"
SRC_URI="https://github.com/PureDarwin/iig-tools/archive/${COMMIT}.tar.gz -> ${P}-${COMMIT}.tar.gz"

S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm64-macos ~x64-macos"

BDEPEND="
	dev-build/cmake
"
DEPEND=""
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/iig-tools-28010c6-codegen-fixes.patch"
)

# Three iig codegen fixes needed by modern XNU DriverKit .iig files:
#  1. parse.cpp nameIdx: the backward identifier scan must skip bracketed
#     array-size expressions ("const char reason[kSomeMacro]") so the size
#     macro token is not mistaken for the parameter name.
#  2. parse.cpp/ast.h/codegen.cpp: raw (non-typedef) arrays with a non-numeric
#     size keep the expression in Param::arraySizeExpr, and isConst
#     "const char *" params (decayed fixed-size buffers) are classified as
#     InBoundedString so the generated code emits a real inline char array
#     (e.g. char __reason[kIOUserServrMaxPanicReasonLength]) rather than an
#     invalid OSDynamicCast.
#  3. parse.cpp/ast.h/codegen.cpp: top-level plain-POD "struct NAME {...};"
#     types (e.g. DeviceParams, DeviceString in IOUserBlockStorageDevice.iig)
#     are registered and their pointer params marshal InStruct/OutStruct by
#     value instead of emitting OSDynamicCast(NAME,...).
# All three were validated against xnu-10063.141.1's DriverKit .iig files;
# without them the generated headers/KEXT impls do not compile.

src_install() {
	dobin "${BUILD_DIR}/iig"
}