{ lib, stdenv, fetchurl, bison, flex  }:

stdenv.mkDerivation rec {
  pname = "bootstrap-cmds";
  version = "138";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/bootstrap_cmds/archive/refs/tags/bootstrap_cmds-138.tar.gz";
    sha256 = "7f86f67c13be04504679170e923c6079e706d57b295f10db752f2f8245f7df8c";
  };

  nativeBuildInputs = [ bison flex ];

  buildCommand = ''
    mkdir -p $out/bin $out/libexec $out/include
    tar -xzf $src --strip-components=1

    # Fix boolean parameter naming collisions
    sed -i.bak 's/strbool( boolean_t bool )/strbool( boolean_t b )/g' migcom.tproj/strdefs.h 2>/dev/null || true
    sed -i.bak 's/strbool(boolean_t bool)/strbool(boolean_t b)/g' migcom.tproj/string.c 2>/dev/null || true
    sed -i.bak 's/if (bool)/if (b)/g' migcom.tproj/string.c 2>/dev/null || true

    cd migcom.tproj
    bison -d -o parser.c parser.y
    ln -sf parser.h y.tab.h
    flex -t lexxer.l > lexxer.c

    sources="error.c global.c header.c mig.c routine.c server.c statement.c string.c type.c user.c utils.c parser.c lexxer.c"
    clang -O2 -D_DARWIN_C_SOURCE -DMIG_VERSION=\"${version}\" -include sys/types.h -I. -Wno-parentheses -Wno-implicit-function-declaration -o migcom $sources

    cp migcom $out/libexec/
    cp mig.sh $out/bin/mig
    chmod +x $out/bin/mig
    ln -sf ../libexec/migcom $out/bin/migcom
  '';

  meta = {
    description = "Mach Interface Generator (mig) from Apple bootstrap_cmds";
    homepage = "https://github.com/apple-oss-distributions/bootstrap_cmds";
    license = "APSL-2.0";
  };
}
