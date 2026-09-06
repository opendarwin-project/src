# OpenDarwin cross-dev image: Gentoo stage3 LLVM plus host Darwin shims.
# Overlay, gentoo tree, and distfiles are bind-mounted at run time (see run.sh).
FROM docker.io/gentoo/stage3:llvm

COPY portage/make.conf /etc/portage/make.conf
COPY portage/repos.conf /etc/portage/repos.conf/gentoo.conf
RUN rm -rf /etc/portage/package.accept_keywords && mkdir -p /etc/portage/package.accept_keywords
COPY portage/package.use /etc/portage/package.use/system
COPY portage/package.accept_keywords /etc/portage/package.accept_keywords/darwin-cross
COPY portage/sysroot.make.conf /usr/share/opendarwin/sysroot.make.conf
COPY portage/patches /etc/portage/patches

RUN mkdir -p \
		/var/db/repos/gentoo \
		/var/db/repos/darwin-cross \
		/var/cache/distfiles \
		/var/cache/binpkgs \
		/usr/arm64-apple-darwin/etc/portage/repos.conf \
		/usr/arm64-apple-darwin/var/cache/binpkgs \
		/usr/arm64-apple-darwin/var/tmp \
		/usr/Platforms/MacOSX.platform \
		/usr/local/src && \
	ln -sfn /etc/portage/repos.conf/gentoo.conf \
		/usr/arm64-apple-darwin/etc/portage/repos.conf/gentoo.conf && \
	cp /usr/share/opendarwin/sysroot.make.conf \
		/usr/arm64-apple-darwin/etc/portage/make.conf && \
	ln -sfn /var/db/repos/gentoo/profiles/prefix/darwin/macos/14.0/arm64/clang \
		/usr/arm64-apple-darwin/etc/portage/make.profile && \
	ln -sfn /var/db/repos/gentoo/profiles/default/linux/amd64/23.0/llvm \
		/etc/portage/make.profile && \
	mkdir -p /usr/arm64-apple-darwin/etc/portage/package.accept_keywords && \
	cp /etc/portage/package.accept_keywords/darwin-cross \
		/usr/arm64-apple-darwin/etc/portage/package.accept_keywords/darwin-cross

# git is needed by xnu's meson subprojects (corecrypto, libdispatch, etc.)
RUN USE="-rust -perl -curl -gpg -pcre -webdav -cvs -subversion -tk -cgi" \
	emerge -q --nodeps dev-vcs/git dev-build/meson

WORKDIR /var/db/repos/darwin-cross
CMD ["/bin/bash"]
