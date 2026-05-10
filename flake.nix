{
  description = "A Lean model and parser playground for the Nix language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs { inherit system; }));
    in
    {
      checks = forAllSystems (pkgs: {
        e2e-smoke = pkgs.runCommand "nixparserlean-e2e-smoke"
          {
            nativeBuildInputs = [
              pkgs.lean4
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.stdenv.cc
            ];
            src = self;
          } ''
          cp -R "$src" source
          chmod -R u+w source
          cd source
          lake build
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/manifest.txt
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/core-validation-manifest.txt --parser "lake exe nixparserlean --core-validation-smoke --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/desugar-manifest.txt --parser "lake exe nixparserlean --desugar --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/eval-manifest.txt --parser "lake exe nixparserlean --eval --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/fuel-manifest.txt --parser "lake exe nixparserlean --eval --fuel 0 --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/json-manifest.txt --parser "lake exe nixparserlean --format json --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/json-manifest.txt --parser "lake exe nixparserlean --desugar --format json --file"
          cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/json-manifest.txt --parser "lake exe nixparserlean --eval --format json --file"
          lake exe nixparserlean --help > help.txt
          case "$(cat help.txt)" in
            *"--format repr|json"* ) ;;
            * ) echo "help output did not mention --format" >&2; exit 1 ;;
          esac
          if lake exe nixparserlean --typo > typo.out 2> typo.err; then
            echo "unknown flag unexpectedly succeeded" >&2
            exit 1
          fi
          case "$(cat typo.err)" in
            *"unknown flag: --typo"* ) ;;
            * ) echo "unknown flag diagnostic was not stable" >&2; cat typo.err >&2; exit 1 ;;
          esac
          touch "$out"
        '';
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.lean4
            pkgs.cargo
            pkgs.rustc
            pkgs.rustfmt
            pkgs.curl
            pkgs.git
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
