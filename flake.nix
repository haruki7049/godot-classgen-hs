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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

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

                cabal2nixArgsOverrides =
                  args:
                  args
                  // {
                    prettyprinter = version: { pgp-wordlist = null; };
                  };

                additionalHaskellPkgSetOverrides = hfinal: hprev: {
                  integer-logarithms = final.haskell.lib.compose.dontCheck hprev.integer-logarithms;
                  prettyprinter = final.haskell.lib.compose.dontCheck hprev.prettyprinter;
                  indexed-traversable-instances = final.haskell.lib.compose.dontCheck hprev.indexed-traversable-instances;
                  integer-conversion = final.haskell.lib.compose.dontCheck hprev.integer-conversion;
                  text-iso8601 = final.haskell.lib.compose.dontCheck hprev.text-iso8601;
                };

                all-cabal-hashes = final.fetchurl {
                  url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/df4fd6587f7e97d8170250ba4419f2cb062736c4.tar.gz";
                  hash = "sha256-kYlq2AWMivC11oYiaYOGu+hBHTkkiWKWM0xlbSuPRe8=";
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

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.ormolu.enable = true;
            programs.mdformat.enable = true;
          };

          packages = {
            default = pkgs.classgen-stacklock.pkgSet.godot-haskell-classgen;
          };

          devShells.default = pkgs.classgen-stacklock.devShell;
        };
    };
}
