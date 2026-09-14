{
  description = "OpenDarwin Package Manager and System Distribution (Swift + Nix)";

  inputs = { };

  outputs = { self }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "arm64e-darwin" ];
      forAllSystems = f: builtins.listToAttrs (builtins.map (system: {
        name = system;
        value = f system;
      }) systems);
    in
    {
      packages = forAllSystems (system:
        import ./pkgs { inherit system; }
      );

      defaultPackage = forAllSystems (system:
        (import ./pkgs { inherit system; }).xnu
      );
    };
}
