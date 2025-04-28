{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

    outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask }:
    let
      username = "ryan.flanagan";
      userHome = "/Users/${username}";
    in {
      darwinConfigurations = {
        default = darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          modules = [
            ({ pkgs, ... }: {
              nix.enable = true;
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              system.stateVersion = 6;

              environment.systemPackages = with pkgs; [
                vim curl wget
              ];

              # Add fish to /etc/shells so it can be set as a login shell
              environment.shells = with pkgs; [ fish bash ];

              users.users.${username} = {
                name = username;
                home = userHome;
                shell = pkgs.fish;
              };

              system.activationScripts.postActivation.text = ''
                echo "Setting ${pkgs.fish}/bin/fish as login shell for ${username}..."
                sudo chsh -s ${pkgs.fish}/bin/fish ${username}
              '';

              programs.fish.enable = true;
            })

            # Install Homebrew
            nix-homebrew.darwinModules.nix-homebrew
            ({
              nix-homebrew = {
                enable = true;
                user = username;
                mutableTaps = false;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };
              };
            })

            # Homebrew package management
            ({
              homebrew = {
                enable = true;
                brews = [
                  "tree"
                  "flox"
                ];
                casks = [
                  "ghostty"
                ];
                onActivation.autoUpdate = true;
              };
            })

            # Home Manager integration
            home-manager.darwinModules.home-manager
            ({
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # backup files before overwriting
              home-manager.backupFileExtension = "backup";

              home-manager.users.${username} = { config, pkgs, ... }: {
                home.stateVersion = "23.11";
                home.username = username;
                home.homeDirectory = userHome;

                programs.home-manager.enable = true;

                home.packages = with pkgs; [
                  ripgrep
                  zellij
                  gh
                  neovim
                  devbox
                ];

                home.file = {
                  ".config/nvim".source = ./.config/nvim;
                  ".config/zellij".source = ./.config/zellij;
                  ".config/ghostty".source = ./.config/ghostty;
                  ".config/starship.toml".source = ./.config/starship.toml;
                };

                programs = {
                  git = {
                    enable = true;
                    extraConfig = {
                      core.editor = "nvim";
                    };
                  };
                  starship.enable = true;

                  fish = {
                    enable = true;
                    # Init starship
                    shellInit = ''
                      source (${pkgs.starship}/bin/starship init fish --print-full-init | psub)
                    '';
                  };
                };
              };
            })
          ];
        };
      };
    };
}
