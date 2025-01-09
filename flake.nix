{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    stacklock2nix.url = "github:cdepillabout/stacklock2nix";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { pkgs, system, ... }:
        let
          overlays = [
            inputs.stacklock2nix.overlay
            (final: prev: {
              classgen-stacklock = final.stacklock2nix {
                stackYaml = ./stack.yaml;
                baseHaskellPkgSet = final.haskell.packages.ghc984;

                additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
                  final.stack
                  final.nil
                ];

                cabal2nixArgsOverrides = args: args // {
                  prettyprinter = version: { pgp-wordlist = null; };
                };

                additionalHaskellPkgSetOverrides = hfinal: hprev: {
                  integer-logarithms = final.haskell.lib.compose.dontCheck hprev.integer-logarithms;
                  prettyprinter = final.haskell.lib.compose.dontCheck hprev.prettyprinter;
                  indexed-traversable-instances = final.haskell.lib.compose.dontCheck hprev.indexed-traversable-instances;
                  integer-conversion = final.haskell.lib.compose.dontCheck hprev.integer-conversion;
                  text-iso8601 = final.haskell.lib.compose.dontCheck hprev.text-iso8601;
                };

                all-cabal-hashes = final.fetchFromGitHub {
                  owner = "commercialhaskell";
                  repo = "all-cabal-hashes";
                  rev = "df4fd6587f7e97d8170250ba4419f2cb062736c4";
                  hash = "sha256-n6VzAT87v2DrMNDsmJXYMTf1a2hhtyx/V5CJkix0cYk=";
                };
              };
            })
          ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system overlays;
            config.allowBroken = true;
          };

          packages = {
            default = pkgs.classgen-stacklock.pkgSet.godot-haskell-classgen;
          };

          devShells.default = pkgs.classgen-stacklock.devShell;
        };
    };
}
