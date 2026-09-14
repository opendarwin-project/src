# OpenDarwin standard environment (stdenv)
{ system ? builtins.currentSystem, defaultNativeBuildInputs ? [ ], defaultUseMold ? false }:

rec {
  inherit system;

  mkDerivation = attrs:
    let
      pname = attrs.pname or (if attrs ? name then attrs.name else "unnamed");
      version = attrs.version or "1.0";
      name = if attrs ? name then attrs.name else "${pname}-${version}";

      # Default builders and standard arguments
      builder = attrs.builder or "/bin/sh";
      args = attrs.args or [ ];

      # Extract build input store paths
      buildInputs = attrs.buildInputs or [ ];
      nativeBuildInputs = defaultNativeBuildInputs ++ (attrs.nativeBuildInputs or [ ]);
      propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];

      inputDrvs = buildInputs ++ nativeBuildInputs ++ propagatedBuildInputs;
      # The final stdenv supplies mold-macho as a native input. Bootstrap
      # stdenv has this disabled, avoiding a dependency cycle while building it.
      useMold = attrs.useMold or defaultUseMold;
      linkerFlags = if useMold then "-fuse-ld=mold" else "";
    in
    derivation (attrs // {
      inherit name pname version system builder args;
      NIX_LDFLAGS = attrs.NIX_LDFLAGS or linkerFlags;
      buildInputs = buildInputs;
      nativeBuildInputs = nativeBuildInputs;
      propagatedBuildInputs = propagatedBuildInputs;
    });
}
