{
  description = "Unified configuration for Darwin and Linux";

  nixConfig = {
    extra-trusted-substituters = [ "https://cache.flox.dev" ];
    extra-trusted-public-keys = [ "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=" ];
  };

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
    
    flox = {
      url = "github:flox/flox/v1.4.0";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, flox }:
  let
    # Darwin configuration
    darwinUsername = "ryan.flanagan";
    darwinUserHome = "/Users/${darwinUsername}";
    darwinSystem = "aarch64-darwin";
    
    # Linux configuration
    linuxUsername = "ryan";
    linuxUserHome = "/home/${linuxUsername}";
    linuxSystem = "x86_64-linux";
    
    # Import nixpkgs for Linux
    linuxPkgs = import nixpkgs {
      system = linuxSystem;
      config.allowUnfree = true;
    };
  in
  {
    # Darwin configuration (for macOS)
    darwinConfigurations = {
      default = darwin.lib.darwinSystem {
        system = darwinSystem;
        modules = [
          ({ pkgs, ... }: {
            nix.enable = true;
            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            system.stateVersion = 6;

            environment.variables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
            };

            environment.systemPackages = [
              pkgs.vim
              pkgs.curl
              pkgs.wget
              flox.packages.${darwinSystem}.default
            ];

            environment.shells = with pkgs; [ fish bash ];

            users.users.${darwinUsername} = {
              name = darwinUsername;
              home = darwinUserHome;
              shell = pkgs.fish;
            };

            programs.fish.enable = true;

            system.activationScripts.postActivation.text = ''
              echo "Setting ${pkgs.fish}/bin/fish as login shell for ${darwinUsername}..."
              sudo chsh -s ${pkgs.fish}/bin/fish ${darwinUsername}
            '';
          })

          nix-homebrew.darwinModules.nix-homebrew
          ({
            nix-homebrew = {
              enable = true;
              user = darwinUsername;
              mutableTaps = false;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
            };
          })

          ({
            homebrew = {
              enable = true;
              brews = [ "tree" ];
              casks = [ "ghostty" "raycast" ];
              onActivation.autoUpdate = true;
            };
          })

          home-manager.darwinModules.home-manager
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.users.${darwinUsername} = { config, pkgs, ... }: {
              home.stateVersion = "23.11";
              home.username = darwinUsername;
              home.homeDirectory = darwinUserHome;

              programs.home-manager.enable = true;

              home.packages = [
                pkgs.ripgrep
                pkgs.zellij
                pkgs.gh
                pkgs.neovim
                pkgs._1password-cli
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
    
    # Linux configuration (for WSL Arch)
    homeConfigurations = {
      "${linuxUsername}" = home-manager.lib.homeManagerConfiguration {
        pkgs = linuxPkgs;
        modules = [
          {
            home.username = linuxUsername;
            home.homeDirectory = linuxUserHome;
            home.stateVersion = "23.11";

            home.packages = [
              linuxPkgs.ripgrep
              linuxPkgs.zellij
              linuxPkgs.gh
              linuxPkgs.neovim
              linuxPkgs._1password-cli
              flox.packages.${linuxSystem}.default
            ];

            programs.home-manager.enable = true;

            home.file = {
              ".config/nvim".source = ./.config/nvim;
              ".config/zellij".source = ./.config/zellij;
              ".config/starship.toml".source = ./.config/starship.toml;
            };

            programs = {
              git = {
                enable = true;
                extraConfig.core.editor = "nvim";
              };
              
              starship.enable = true;

              fish = {
                enable = true;
                shellInit = ''
                  source (${linuxPkgs.starship}/bin/starship init fish --print-full-init | psub)
                  set -gx EDITOR nvim
                  set -gx VISUAL nvim
                  set -gx FLOX_SHELL fish
                '';
                shellAliases = {
                  fa = "flox activate --shell fish";
                };
              };
            };
          }
        ];
      };
    };
  };
}
