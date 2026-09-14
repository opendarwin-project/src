{ lib, stdenv, fetchurl, cmake, ninja, python3, unifdef, bison, flex, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, xcbuild  }:

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
  runtime_c = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-libs/libsystem/files/libsystem_runtime.c";
    sha256 = "642ed132ecc182c7b385b0fbb08f5d76295c2df4c428b0bdde13cb5e5b722470";
  };

  nativeBuildInputs = [ cmake ninja unifdef bison flex bootstrap-cmds iig-tools xcode-toolchain-wrappers xcbuild ];

  buildCommand = ''
    mkdir -p $out/lib $out/include/mach $out/include/sys $out/include/pthread $out/include/dispatch $out/include/os $out/include/bsm $out/include/mach-o

    # Unpack resources
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

    # Compile libSystem.B text stub (.tbd) and dynamic library
    cat << 'EOF' > $out/lib/libSystem.B.tbd
--- !tapi-tbd
tbd-version: 4
targets: [ arm64-macos, x86_64-macos ]
install-name: /usr/lib/libSystem.B.dylib
current-version: 1356.0.0
compatibility-version: 1.0.0
exports:
  - targets: [ arm64-macos, x86_64-macos ]
    symbols:
      - dyld_stub_binder
      - ___error
      - ___stack_chk_fail
      - ___stack_chk_guard
      - _exit
      - __exit
      - _abort
      - _getpid
      - _getppid
      - _getuid
      - _geteuid
      - _getgid
      - _getegid
      - _read
      - _write
      - _open
      - _close
      - _unlink
      - _chdir
      - _fchdir
      - _chmod
      - _chown
      - _dup
      - _pipe
      - _fcntl
      - _fsync
      - _mkdir
      - _rmdir
      - _rename
      - _access
      - _mmap
      - _munmap
      - _malloc
      - _free
      - _calloc
      - _realloc
      - _strdup
      - _memcpy
      - _memset
      - _memmove
      - _memcmp
      - _strlen
      - _strcmp
      - _strncmp
      - _strcpy
      - _strncpy
      - _strcat
      - _strncat
      - _strchr
      - _strrchr
      - _strstr
      - _puts
      - _printf
      - _sprintf
      - _snprintf
      - ___snprintf_chk
      - ___sprintf_chk
      - _pthread_mutex_init
      - _pthread_mutex_lock
      - _pthread_mutex_unlock
      - _pthread_mutex_destroy
      - _pthread_once
...
EOF

    target_triple="${if stdenv.system == "x86_64-darwin" then "x86_64-apple-darwin" else "arm64-apple-darwin"}"
    clang -target "$target_triple" \
      -fno-stack-protector -ffreestanding -dynamiclib \
      -install_name /usr/lib/libSystem.B.dylib \
      -compatibility_version 1.0 -current_version 1356.0 \
      -nostdlib \
      -o $out/lib/libSystem.B.dylib \
      $runtime_c || true

    ln -sf libSystem.B.dylib $out/lib/libSystem.dylib
    ln -sf libSystem.B.tbd $out/lib/libSystem.tbd
    ln -sf libSystem.B.dylib $out/lib/libc.dylib
    ln -sf libSystem.B.dylib $out/lib/libm.dylib
    ln -sf libSystem.B.dylib $out/lib/libpthread.dylib
    ln -sf libSystem.B.dylib $out/lib/libdl.dylib

    # Install primary Darwin / XNU headers
    cp -R Libc/include/* $out/include/ 2>/dev/null || true
    cp -R libpthread/include/* $out/include/ 2>/dev/null || true
    cp -R libplatform/include/* $out/include/ 2>/dev/null || true
    cp -R libmalloc/include/* $out/include/ 2>/dev/null || true
    cp -R libdispatch/dispatch/* $out/include/dispatch/ 2>/dev/null || true
    cp -R libdispatch/os/* $out/include/os/ 2>/dev/null || true
    cp -R CarbonHeaders/*.h $out/include/ 2>/dev/null || true
    cp -R OpenBSM/openbsm/bsm/*.h $out/include/bsm/ 2>/dev/null || true
    cp -R dyld/include/* $out/include/ 2>/dev/null || true

    ln -sf pthread/pthread.h $out/include/pthread.h 2>/dev/null || true
    ln -sf pthread/sched.h $out/include/sched.h 2>/dev/null || true
  '';

  meta = {
    description = "Open source Darwin libSystem runtime and headers for cross-compilation";
    homepage = "https://github.com/apple-oss-distributions/libsystem";
    license = [ "APSL-2.0" "MIT" ];
  };
}
