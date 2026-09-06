# Copyright 2026 OpenDarwin / Portage contributors
# Distributed under the terms of the MIT license

EAPI=8
inherit toolchain-funcs

DESCRIPTION="Mach Interface Generator (mig) from Apple bootstrap_cmds"
HOMEPAGE="https://github.com/apple-oss-distributions/bootstrap_cmds"
SRC_URI="https://github.com/apple-oss-distributions/bootstrap_cmds/archive/refs/tags/bootstrap_cmds-${PV}.tar.gz -> bootstrap_cmds-${PV}.tar.gz"

S="${WORKDIR}/bootstrap_cmds-bootstrap_cmds-${PV}"

LICENSE="APSL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~arm64-macos ~x64-macos"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
"

src_prepare() {
	default

	local inc="${T}/mig_compat"
	mkdir -p "${inc}/mach" "${inc}/machine" "${inc}/sys" || die
	touch "${inc}/sys/_symbol_aliasing.h" || die
	cp "${FILESDIR}/host_compat.h" "${inc}/" || die
	cp "${FILESDIR}/mach_boolean.h" "${inc}/mach/boolean.h" || die
	cp "${FILESDIR}/mach_message.h" "${inc}/mach/message.h" || die
	cp "${FILESDIR}/mach_ndr.h" "${inc}/mach/ndr.h" || die
	cp "${FILESDIR}/mach_std_types.h" "${inc}/mach/std_types.h" || die
	cp "${FILESDIR}/mach_kern_return.h" "${inc}/mach/kern_return.h" || die
	cp "${FILESDIR}/machine_limits.h" "${inc}/machine/limits.h" || die

	# mig.sh hardcodes /usr/bin/xcrun and /usr/bin/arch and preprocesses its
	# .defs input with "-arch $(uname -m)"; none of those work on a Linux
	# cross host. Resolve xcrun via PATH and select the triple via CTARGET.
	eapply "${FILESDIR}/bootstrap_cmds-138-mig-linux.patch"

	sed -i 's/strbool( boolean_t bool )/strbool( boolean_t b )/g' "${S}/migcom.tproj/strdefs.h" || die

	sed -i 's/strbool(boolean_t bool)/strbool(boolean_t b)/g; s/if (bool)/if (b)/g' "${S}/migcom.tproj/string.c" || die
}

src_compile() {
	cd "${S}/migcom.tproj" || die
	bison -d -o parser.c parser.y || die
	ln -sf parser.h y.tab.h || die
	flex -t lexxer.l > lexxer.c || die

	local cflags=(
		${CFLAGS}
		-O2
		-include "${T}/mig_compat/host_compat.h"
		-I.
		-I"${T}/mig_compat"
		-Wno-parentheses
	)

	local sources=(
		error.c global.c header.c mig.c routine.c server.c
		statement.c string.c type.c user.c utils.c parser.c lexxer.c
	)

	$(tc-getCC) "${cflags[@]}" ${LDFLAGS} -o migcom "${sources[@]}" || die
}

src_install() {
	exeinto /usr/libexec
	doexe "${S}/migcom.tproj/migcom"

	dobin "${S}/migcom.tproj/mig.sh"
	mv "${ED}/usr/bin/mig.sh" "${ED}/usr/bin/mig" || die
	# mig.sh and xcrun -find both look on PATH; the binary lives in libexec.
	dosym ../libexec/migcom /usr/bin/migcom
}
