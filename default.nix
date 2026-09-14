# OpenDarwin Nix Root Entrypoint
{ system ? builtins.currentSystem }:

import ./pkgs/default.nix { inherit system; }
