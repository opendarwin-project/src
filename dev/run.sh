#!/usr/bin/env bash
# Run the OpenDarwin Gentoo stage3 container with overlay / tree / distfiles mounted.
# Host-tool merges persist in a named container (opendarwin-dev); the Darwin
# sysroot is bind-mounted from the host.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${OPENDARWIN_IMAGE:-localhost/opendarwin-dev:llvm}"
NAME="${OPENDARWIN_CONTAINER:-opendarwin-dev}"
GENTOO_REPO="${GENTOO_REPO:-/var/db/repos/gentoo}"
DISTFILES="${DISTFILES:-${HOME}/.gentoo/var/cache/distfiles}"
OVERLAY="${OVERLAY:-${ROOT}/overlay}"
SYSROOT="${SYSROOT:-${ROOT}/sysroot/arm64-apple-darwin}"

if [[ ! -d "${GENTOO_REPO}/profiles" ]]; then
	echo "gentoo repo not found at ${GENTOO_REPO}" >&2
	exit 1
fi
mkdir -p "${DISTFILES}" "${SYSROOT}"

if [[ ! -e "${SYSROOT}/etc/portage/make.conf" ]]; then
	mkdir -p "${SYSROOT}/etc/portage/repos.conf" \
		"${SYSROOT}/etc/portage/package.accept_keywords" \
		"${SYSROOT}/var/cache/binpkgs" \
		"${SYSROOT}/var/tmp"
	cp "${ROOT}/dev/portage/sysroot.make.conf" "${SYSROOT}/etc/portage/make.conf"
	cp "${ROOT}/dev/portage/repos.conf" "${SYSROOT}/etc/portage/repos.conf/gentoo.conf"
	cp "${ROOT}/dev/portage/package.accept_keywords" \
		"${SYSROOT}/etc/portage/package.accept_keywords/darwin-cross"
	ln -sfn /var/db/repos/gentoo/profiles/prefix/darwin/macos/14.0/arm64/clang \
		"${SYSROOT}/etc/portage/make.profile"
fi

tty_flags=()
if [[ -t 0 && -t 1 ]]; then
	tty_flags=(-it)
fi

if ! podman container exists "${NAME}"; then
	podman run -d --name "${NAME}" \
		--cgroup-manager=cgroupfs \
		-v "${OVERLAY}:/var/db/repos/darwin-cross:Z" \
		-v "${GENTOO_REPO}:/var/db/repos/gentoo:ro,Z" \
		-v "${DISTFILES}:/var/cache/distfiles:Z" \
		-v "${ROOT}:/src/opendarwin-work:Z" \
		-v "${SYSROOT}:/usr/arm64-apple-darwin:Z" \
		-w /var/db/repos/darwin-cross \
		"${IMAGE}" \
		sleep infinity >/dev/null
fi

if ! podman inspect -f '{{.State.Running}}' "${NAME}" | grep -qx true; then
	podman start "${NAME}" >/dev/null
fi

if [[ $# -eq 0 ]]; then
	set -- bash
fi
exec podman exec "${tty_flags[@]}" "${NAME}" "$@"
