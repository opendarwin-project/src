{ stdenv, fetchurl, gnumake  }:

stdenv.mkDerivation rec {
  pname = "cmake";
  version = "4.3.5";

  src = fetchurl {
    url = "https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}.tar.gz";
    sha256 = "24fc974191ef48da4ff309671fdb5989f43e07ecde0e2589eaf9d72672d8612b";
  };

  nativeBuildInputs = [
    gnumake
  ];

  configurePhase = ''
    NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    ./bootstrap --prefix=$out --parallel=$NCPUS -- -DCMAKE_USE_OPENSSL=OFF
  '';

  buildPhase = ''
    NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    make -j$NCPUS
  '';

  installPhase = ''
    make install
  '';

  meta = {
    description = "Cross-platform open-source build system";
    homepage = "https://cmake.org/";
  };
}
