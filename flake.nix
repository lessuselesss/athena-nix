{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      username = "athena";
      theme = "temple";
      desktop = "gnome";
      dmanager = "sddm";
      mainShell = "fish";
      terminal = "kitty";
      browser = "firefox";
      bootloader = if builtins.pathExists "/sys/firmware/efi" then "systemd" else "grub";
      mkSystem = extraModules:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ lib, pkgs, config, ...}: let
            hostname = "athenaos";
            hashed = "$6$51FcT2TE8N/xevYZ$MOHuVXzAdId21vqURO9NjmMVskLBcaSW9lQBYEKK4dXXvyycW3HnRr5nJZvKjwDcLF/c9JVa8AsdbWdFobyWK.";
            hashedRoot = "$6$51FcT2TE8N/xevYZ$MOHuVXzAdId21vqURO9NjmMVskLBcaSW9lQBYEKK4dXXvyycW3HnRr5nJZvKjwDcLF/c9JVa8AsdbWdFobyWK.";
          in {
            networking.hostName = "${hostname}";
            users = lib.mkIf config.athena.enable {
              mutableUsers = false;
              extraUsers.root.hashedPassword = "${hashedRoot}";
              users.${config.athena.homeManagerUser} = {
                shell = pkgs.${config.athena.mainShell};
                isNormalUser = true;
                hashedPassword = "${hashed}";
                extraGroups = [ "wheel" "input" "video" "render" "networkmanager" ];
              };
            };
          })
        ] ++ extraModules;
      };
    in {
      nixosConfigurations = {
        # nix build .#nixosConfigurations.live-image.config.system.build.isoImage
        "live-image" = mkSystem [
          ./nixos/installation/iso.nix
          home-manager.nixosModules.home-manager
          ./nixos
          {
            athena = {
              enable = true;
              baseHosts = true;
              baseLocale = true;
              homeManagerUser = "athena";
              desktopManager = "mate";
              terminal = "alacritty";
              theme = "graphite";
            };
          }
        ];

        "runtime" = mkSystem [
          "/etc/nixos/hardware-configuration.nix"
          home-manager.nixosModules.home-manager
          ./nixos
          {
          athena = {
            inherit bootloader terminal theme mainShell browser;
            enable = true;
            baseConfiguration = true;
            baseSoftware = true;
            baseLocale = true;
            homeManagerUser = username;
            desktopManager = desktop;
            displayManager = dmanager;
          };
          }
        ];

        "student" = mkSystem [
          "/etc/nixos/hardware-configuration.nix"
          ./nixos/modules/roles/student
        ];
      };

      packages."x86_64-linux" = (builtins.mapAttrs (n: v: v.config.system.build.isoImage) self.nixosConfigurations) // {
        default = self.packages."x86_64-linux"."live-image";
      };

      nixosModules = rec {
        athena = ./nixos;
        default = athena;
      };
    };
}
