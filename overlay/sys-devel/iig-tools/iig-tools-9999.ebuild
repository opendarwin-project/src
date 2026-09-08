# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

COMMIT="96c1ece6be1ceb6ee2fec6c434d080edc10da2b1"

DESCRIPTION="An iig-tools implementation for I/O Kit Interface Generator"
HOMEPAGE="https://github.com/opendarwin-project/iig-tools"
SRC_URI="https://github.com/opendarwin-project/iig-tools/archive/${COMMIT}.tar.gz -> ${P}-${COMMIT}.tar.gz"

S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm64-macos ~x64-macos"

BDEPEND="
	dev-build/cmake
"
DEPEND=""
RDEPEND="${DEPEND}"
