{
  description = "ShmerV RISC-V CPU development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Development tools
              gnumake
              just
              python3
              zsh

              # RTL development
              slang-server
              surfer
              verible
              verilator
              yosys

              # RISC-V software toolchain
              dtc
              pkgsCross.riscv32-embedded.stdenv.cc
              spike

              # Documentation and diagrams
              drawio
              graphviz
              netlistsvg
              typst

              # Build dependencies
              lz4
              zlib
            ];
          };
        });
    };
}
