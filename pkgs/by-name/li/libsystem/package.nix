{ lib, stdenv, fetchurl, cmake, ninja, python3, unifdef, bison, flex, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, xcbuild, xnu-headers  }:

# A real, linkable and loadable libSystem.B.dylib.
#
# The umbrella dylib is built the way Apple builds it: from the Libsystem
# project's CompatibilityHacks.c plus -reexport of the real sub-libraries
# (libsystem_c, libsystem_malloc, libsystem_platform, ...).  The Apple Open
# Source component sources are unpacked so their public/private headers can be
# installed alongside it.
#
# The remaining Apple Open Source components (Libc, libpthread, libplatform,
# libmalloc, libdispatch, dyld, ...) are unpacked so their public headers are
# installed alongside the runtime, giving a self-contained SDK prefix.
stdenv.mkDerivation rec {
  pname = "libsystem";
  version = "1356";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libsystem/archive/refs/tags/Libsystem-1356.tar.gz";
    sha256 = "4bc7151681df1ef1aa2328ee533d62ec10eb7f94912902d25fec772febd9353c";
  };

  # Auxiliary Apple Open Source Components
  xnu_src = fetchurl {
    url = "https://github.com/opendarwin-project/xnu/archive/901f4bd84bb0f8d663110120edfa157068e064ba.tar.gz";
    sha256 = "eac9191d9ffa996e17bd58a15f8ea168ec81a30368689fa779b0e9b9922738e6";
  };

  libc_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/Libc/archive/refs/tags/Libc-1592.100.35.tar.gz";
    sha256 = "1f75aa26cb41039f6ee2b13781ec58f1060eb2202aae1847ac2e883d2cb9c9c0";
  };
  libpthread_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libpthread/archive/refs/tags/libpthread-519.120.4.tar.gz";
    sha256 = "82f9ec53344f80b164535b47a12bac05eec6ffb78130ea0f016a9cb2e904aa04";
  };
  libplatform_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libplatform/archive/refs/tags/libplatform-316.100.10.tar.gz";
    sha256 = "5de737c41efa455b1514af6e4fac87a5479e466b384dedf9dfcad25b0fb0388e";
  };
  libmalloc_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libmalloc/archive/refs/tags/libmalloc-521.120.7.tar.gz";
    sha256 = "d269569ecdb57237e5b4af8606dc6202a4c6572bfc6fef8d63148249c37d85b6";
  };
  availability_versions_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-157.2.tar.gz";
    sha256 = "d92a052edb3c817caa4407868f66f1d93727425a353c2200a41481c27310fdc2";
  };
  openbsm_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/OpenBSM/archive/refs/tags/OpenBSM-21.tar.gz";
    sha256 = "ebbd23f36c08da9bae0d6f14727892e83f352cc50a4e8fdaf3f9f9137381de6b";
  };
  carbon_headers_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/CarbonHeaders/archive/refs/tags/CarbonHeaders-18.1.tar.gz";
    sha256 = "50d687bf1cd8cc4067618ba830ba96515a6b65ae96aa7ff75e57a8482728d39d";
  };
  libdispatch_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-1542.100.32.tar.gz";
    sha256 = "b251152f46d2cc16b87be85d32880144b44aadab62eb0712c31b27ca86556718";
  };
  dyld_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/dyld/archive/refs/tags/dyld-1378.tar.gz";
    sha256 = "509c8b081153a7b9ff08d6ddf0a681c0ab5190e1e336ef2e9748b801bdb9c59e";
  };

  # Use OpenDarwin's xcrun from xcbuild, never the host Xcode tools.
  nativeBuildInputs = [ xcbuild ];
  buildInputs = [ xnu-headers ];

  buildCommand = ''
    mkdir -p $out/lib $out/include/mach $out/include/sys $out/include/pthread $out/include/dispatch $out/include/os $out/include/bsm $out/include/mach-o

    # Unpack resources (headers + reference sources)
    mkdir -p xnu Libc libpthread libplatform libmalloc AvailabilityVersions OpenBSM CarbonHeaders libdispatch dyld
    tar -xzf $xnu_src -C xnu --strip-components=1
    tar -xzf $libc_src -C Libc --strip-components=1
    tar -xzf $libpthread_src -C libpthread --strip-components=1
    tar -xzf $libplatform_src -C libplatform --strip-components=1
    tar -xzf $libmalloc_src -C libmalloc --strip-components=1
    tar -xzf $availability_versions_src -C AvailabilityVersions --strip-components=1
    tar -xzf $openbsm_src -C OpenBSM --strip-components=1
    tar -xzf $carbon_headers_src -C CarbonHeaders --strip-components=1
    tar -xzf $libdispatch_src -C libdispatch --strip-components=1
    tar -xzf $dyld_src -C dyld --strip-components=1
    patch -d dyld -p1 < ${./files/dyld-1378-exclavekit.patch}
    patch -d xnu -p1 < ${./files/xnu-os-log-userspace.patch}

    # Build the real libSystem.B.dylib.
    #
    # Apple's libSystem is a thin umbrella dylib (the Libsystem project's
    # init.c + CompatibilityHacks.c) that *reexports* the real sub-libraries:
    # libsystem_c, libsystem_malloc, libsystem_platform, libsystem_pthread,
    # libsystem_kernel, libsystem_m, libdispatch, libxpc, libdyld, ...
    #
    # Reproduce the project's linker_arguments.sh: pick the sub-libraries that
    # exist in the SDK and -reexport them, and emit the HAVE_* config header.
    target_arch="${if stdenv.system == "x86_64-darwin" then "x86_64" else "arm64"}"
    XCRUN="$(type -P xcrun)"
    test -n "$XCRUN"
    SDKROOT="$($XCRUN --sdk macosx --show-sdk-path)"
    LSYS="$SDKROOT/usr/lib/system"

    mkdir -p libsystem-proj
    tar -xzf $src -C libsystem-proj --strip-components=1

    CONFIG="$PWD/libsystem-proj/config.$target_arch.normal.h"
    REEXPORTS="$PWD/libsystem-proj/linker_arguments.$target_arch.normal.txt"
    : > "$CONFIG"; : > "$REEXPORTS"
    while read -r line; do
      for lib in $line; do
        if [ -e "$LSYS/lib''${lib}.tbd" ]; then
          U=$(echo "$lib" | tr 'a-z' 'A-Z' | sed 's/_SIM//')
          echo "#define HAVE_''${U} 1" >> "$CONFIG"
          echo "-Wl,-reexport-l''${lib}" >> "$REEXPORTS"
          break
        fi
      done
    done < libsystem-proj/requiredlibs

    clang -arch "$target_arch" -isysroot "$SDKROOT" -O2 -c \
      -include "$CONFIG" -DCURRENT_VARIANT_normal=1 \
      libsystem-proj/CompatibilityHacks.c -o compat.o

    clang -arch "$target_arch" -isysroot "$SDKROOT" -dynamiclib -nostdlib \
      -install_name /usr/lib/libSystem.B.dylib \
      -compatibility_version 1.0 -current_version 1356.0 \
      -L"$LSYS" @$REEXPORTS compat.o \
      -o $out/lib/libSystem.B.dylib

    # Generate a text-based stub from the dylib's actual exports so that
    # `-lSystem` resolves to this umbrella instead of the host SDK stub.
    "$XCRUN" tapi stubify --filetype=tbd-v4 \
      -o $out/lib/libSystem.B.tbd $out/lib/libSystem.B.dylib
    ln -sf libSystem.B.tbd $out/lib/libSystem.tbd

    # Install private headers that are not part of the public SDK.
    #
    # Public Libc/libpthread/libmalloc/libdispatch headers are intentionally not
    # installed: the host SDK already ships ABI-compatible, internally
    # consistent versions, and shadowing them with the OSS source copies breaks
    # consumers (stale availability macros, libc++'s <stddef.h>, ...).
    mkdir -p $out/include/System
    cp -R ${xnu-headers}/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders/* $out/include/System/ 2>/dev/null || true
    cp -R ${xnu-headers}/usr/local/include/* $out/include/ 2>/dev/null || true

    # xnu's `make installhdrs` also emits a copy of the *public* usr/include tree
    # (sys/, mach/, ...).  Those must NOT shadow the SDK's ABI-compatible public
    # headers, so only install the ones the SDK does not ship.
    SDK_INC="$($XCRUN --sdk macosx --show-sdk-path)/usr/include"
    if [ -d ${xnu-headers}/usr/include ]; then
      (cd ${xnu-headers}/usr/include && find . -type f) | while read -r h; do
        # The internal Availability* family must be installed as a whole: mixing
        # Apple's AvailabilityVersions macros with the SDK's Availability.h (or
        # vice versa) produces an inconsistent __SPI_AVAILABLE/__API_AVAILABLE.
        case "$h" in
          ./Availability.h|./AvailabilityInternal.h|./AvailabilityInternalLegacy.h|./AvailabilityMacros.h|./AvailabilityVersions.h|./os/availability.h)
            ;;
          *)
            [ -e "$SDK_INC/$h" ] && continue
            ;;
        esac
        mkdir -p "$out/include/$(dirname "$h")"
        cp "${xnu-headers}/usr/include/$h" "$out/include/$h"
      done
    fi

    # os/log_private.h lives in xnu's libkern sources and is not part of installhdrs.
    # The kernel source tree is the only local source for this private header;
    # patch it above with the small userspace declarations required by Libc.
    mkdir -p $out/include/os
    if [ -f xnu/libkern/os/log_private.h ]; then
      cp xnu/libkern/os/log_private.h $out/include/os/log_private.h
    fi

    # XNU's exported external headers (corecrypto, libDER, ...).
    cp -R xnu/EXTERNAL_HEADERS/corecrypto $out/include/ 2>/dev/null || true
    cp -R xnu/EXTERNAL_HEADERS/libDER $out/include/ 2>/dev/null || true

    # libplatform private/public headers (e.g. <_simple.h>, <os/...>).
    cp -R libplatform/private/* $out/include/ 2>/dev/null || true
    cp -R libplatform/internal/* $out/include/ 2>/dev/null || true
    cp -R libplatform/include/* $out/include/ 2>/dev/null || true

    # libpthread private headers (<pthread/tsd_private.h>, <pthread/private.h>, ...).
    cp -R libpthread/private/* $out/include/ 2>/dev/null || true

    # Libc's private headers (<libc_private.h>, <_libc_init.h>, ...).
    cp -R Libc/darwin/*.h $out/include/ 2>/dev/null || true
    cp -R Libc/os/*.h $out/include/ 2>/dev/null || true
    cp -R Libc/locale/*.h $out/include/ 2>/dev/null || true
    cp -R Libc/gen/*.h $out/include/ 2>/dev/null || true

    # dyld's own headers (public mach-o/dyld.h plus private dyld_priv.h).
    cp -R dyld/include/* $out/include/ 2>/dev/null || true
    # The dyld source was patched before installation above; do not mutate
    # generated headers with ad-hoc sed/perl commands.

    # Bootstrap shim: CrashReporterClient is not open source.  dyld only uses it
    # for diagnostic log messages, so provide no-op macros.
    cat > $out/include/CrashReporterClient.h <<'EOF'
#ifndef _CRASHREPORTERCLIENT_H_
#define _CRASHREPORTERCLIENT_H_
#define CRSetCrashLogMessage(x) ((void)0)
#define CRSetCrashLogMessage2(x) ((void)0)
#endif
EOF
  '';

  meta = {
    description = "Open source Darwin libSystem runtime and headers for cross-compilation";
    homepage = "https://github.com/apple-oss-distributions/libsystem";
    license = [ "APSL-2.0" "MIT" ];
  };
}
