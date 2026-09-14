{ lib, stdenv, fetchurl }:

let
  version = "1.98.1";
  targetMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      sha256 = "cfc171d8120d401b10a1028c52646dd8e00e3e66852f949061ce087845f55afd";
    };
    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      sha256 = "443a1165abbac41c9143b83ff837c0fb1d8c03d2f8fb1da27427bc9fc646aad3";
    };
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      sha256 = "24ba1338a2d35c5a3247936546429e163fa674d726102af18bdf624582c57aea";
    };
    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      sha256 = "f00ba576645cef658e1deed96fab8f707958e9d58808b16343448b5d1c4f7407";
    };
  };
  selected = targetMap.${stdenv.system} or (targetMap."aarch64-darwin");
in
stdenv.mkDerivation rec {
  pname = "rust-bin";
  inherit version;

  src = fetchurl {
    url = "https://static.rust-lang.org/dist/rust-${version}-${selected.target}.tar.gz";
    sha256 = selected.sha256;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    ./install.sh --prefix=$out --disable-ldconfig --without=rust-docs 2>/dev/null || ./install.sh --prefix=$out --disable-ldconfig
  '';

  meta = {
    description = "Empowering everyone to build reliable and efficient software";
    homepage = "https://www.rust-lang.org/";
  };
}
