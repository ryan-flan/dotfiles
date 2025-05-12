{
  description = "Darwin configuration";

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
    username = "ryan.flanagan";
    userHome = "/Users/${username}";
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations = {
      default = darwin.lib.darwinSystem {
        system = system;
        modules = [
          ({ pkgs, ... }: {
            nix.enable = true;
            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            system.stateVersion = 6;

            # Set environment variables system-wide
            environment.variables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
            };

            environment.systemPackages = [
              pkgs.vim
              pkgs.curl
              pkgs.wget
              flox.packages.${system}.default
            ];

            environment.shells = with pkgs; [ fish bash ];

            users.users.${username} = {
              name = username;
              home = userHome;
              shell = pkgs.fish;
            };

            programs.fish.enable = true;

            system.activationScripts.postActivation.text = ''
              echo "Setting ${pkgs.fish}/bin/fish as login shell for ${username}..."
              sudo chsh -s ${pkgs.fish}/bin/fish ${username}
            '';
          })

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

          ({
            homebrew = {
              enable = true;
              brews = [
                "tree"
              ];
              casks = [
                "ghostty"
                "raycast"
              ];
              onActivation.autoUpdate = true;
            };
          })

          home-manager.darwinModules.home-manager
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.users.${username} = { config, pkgs, ... }: {
              home.stateVersion = "23.11";
              home.username = username;
              home.homeDirectory = userHome;

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
  };
}
