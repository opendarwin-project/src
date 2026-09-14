{ lib, stdenv, fetchurl  }:

stdenv.mkDerivation rec {
  pname = "tar";
  version = "1.35";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz";
    sha256 = "4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16";
  };

  patches = [
    (fetchurl {
      url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/app-arch/tar/tar-1.35-libiconv.patch";
      sha256 = "a6a544780d892f259b7c5636b05345d16dfbe9fa24db0c87c0590a6da7b18d6a";
    })
  ];

  patchPhase = ''
    find . -exec touch -r configure {} + 2>/dev/null || true
  '';

  configureFlags = "--disable-gcc-warnings --enable-backup-scripts --program-prefix=g gl_cv_warn_c__fanalyzer=no LIBS=-liconv";
  makeFlags = "LIBS=-liconv";

  fixupPhase = ''
    ln -sf gtar $out/bin/tar
    ln -sf gtar.1 $out/share/man/man1/tar.1 2>/dev/null || true
  '';

  meta = {
    description = "GNU version of the tar archiving utility with libiconv support";
    homepage = "https://www.gnu.org/software/tar/";
    license = "GPL-3.0-or-later";
  };
}
