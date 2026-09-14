{ lib, stdenv, fetchurl, cmake, ninja, python3  }:

stdenv.mkDerivation rec {
  pname = "lld";
  version = "23.1.1";

  src = fetchurl {
    url = "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${version}.tar.gz";
    sha256 = "851b3d701a4fbdd9f69536d4acda578469e810ca7056687d6556443f5fd39557";
  };

  nativeBuildInputs = [ cmake ninja python3 ];

  cmakeFlags = [
    "-S ../lld"
    # "-DLLVM_ENABLE_PROJECTS=lld"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_TARGETS_TO_BUILD=AArch64;X86;ARM"
    "-DLLVM_INCLUDE_TESTS=OFF"
    "-DLLVM_INCLUDE_EXAMPLES=OFF"
    "-DLLVM_INCLUDE_BENCHMARKS=OFF"
    "-DLLVM_ENABLE_BINDINGS=OFF"
  ];

  installPhase = ''
    ninja -C build install
    ln -sf lld $out/bin/ld.lld
    ln -sf lld $out/bin/ld64.lld
    ln -sf lld $out/bin/wasm-ld
  '';

  meta = {
    description = "The LLVM Linker (LLD)";
    homepage = "https://lld.llvm.org/";
  };
}
