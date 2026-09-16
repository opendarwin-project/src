{ lib, stdenv }:

# The three tools this package provides (sw_vers, codesign, sysctl) are part of
# base macOS, not Xcode. The original package fetched prebuilt wrapper scripts
# from an overlay path that no longer exists, so provide them directly.
stdenv.mkDerivation {
  pname = "xcode-toolchain-wrappers";
  version = "1.0.0";

  buildCommand = ''
    mkdir -p $out/bin $out/libexec/darwin
    ln -sf /usr/bin/sw_vers $out/bin/sw_vers
    ln -sf /usr/bin/codesign $out/bin/codesign
    ln -sf /usr/bin/sysctl $out/libexec/darwin/sysctl
    ln -sf codesign $out/bin/codesign_allocate
  '';

  meta = {
    description = "Xcode toolchain compatibility wrappers (sw_vers, codesign, sysctl) for LLVM";
    homepage = "https://github.com/opendarwin-project";
    license = "MIT";
  };
}
