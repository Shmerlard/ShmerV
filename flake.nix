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
          zshSetup = pkgs.writeTextDir ".zshrc" ''
            # Preserve the user's usual zsh configuration.
            if [[ -n $SHMERV_PREVIOUS_ZDOTDIR ]]; then
              export ZDOTDIR=$SHMERV_PREVIOUS_ZDOTDIR
            else
              unset ZDOTDIR
            fi
            [[ -r ''${ZDOTDIR:-$HOME}/.zshenv ]] && source "''${ZDOTDIR:-$HOME}/.zshenv"
            [[ -r ''${ZDOTDIR:-$HOME}/.zshrc ]] && source "''${ZDOTDIR:-$HOME}/.zshrc"
            source "$SHMERV_PROJECT_ROOT/scripts/completion/just.zsh"
          '';
        in {
          default = pkgs.mkShell {
            shellHook = ''
              # direnv cannot install functions in its parent zsh process.
              # Configure only shells launched by nix develop.
              if [[ -z "''${DIRENV_IN_ENVRC:-}" ]]; then
                export SHMERV_PROJECT_ROOT="$PWD"
                export SHMERV_PREVIOUS_ZDOTDIR="''${ZDOTDIR:-}"
                export ZDOTDIR="${zshSetup}"
                if [[ $- == *i* && -z "''${ZSH_VERSION:-}" ]]; then
                  exec ${pkgs.zsh}/bin/zsh
                fi
              fi
            '';
            packages = with pkgs; [
              # Development tools
              gnumake
              just
              python3
              xdg-terminal-exec
              zsh

              # RTL development
              slang-server
              surfer
              verible
              verilator
              yosys
              nextpnr
              openfpgaloader
              python3Packages.apycula

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
