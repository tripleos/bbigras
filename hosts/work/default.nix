{ lib, pkgs, nur, nixos-hardware, ... }:

let
  nurNoPkgs = import nur { pkgs = null; nurpkgs = pkgs; };
in
{
  imports = with nixos-hardware.nixosModules;
    [
      ../../core
      ../../dev

      # Include the results of the hardware scan.
      ../../hardware/hardware-configuration-work.nix
      ../../hardware/efi.nix
      ../../hardware/sound.nix

      common-pc
      common-pc-ssd
      common-cpu-intel

      ../../graphical
      ../../graphical/sway.nix
      ../../graphical/trusted.nix
      ../../dev/virt-manager.nix

      ../../users/bbigras
    ] ++ (if builtins.pathExists (builtins.getEnv "PWD" + "/secrets/at_work.nix") then [ (builtins.getEnv "PWD" + "/secrets/at_work.nix") ] else [ ]);

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    # "fs.inotify.max_user_watches" = 524288;
    # "vm.swappiness" = 1;
  };

  age.rekey = {
    masterIdentities = [ "/home/bbigras/.config/age/keys/bbigras.age" ];
  };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [ linuxPackages_zen.bcc ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/ccb4db0b-1cb8-4d5f-be9a-8b20a5c63982";
      fsType = "btrfs";
      options = [ "subvol=nixos" "compress=zstd" ];
    };

  services.printing = {
    enable = true;
    drivers = with pkgs; [ postscript-lexmark hplip ];
  };

  services.yggdrasil.enable = lib.mkForce false;

  networking = {
    hostName = "bbigras-work";
  };

  home-manager.users.bbigras = {
    imports = [
      ../../users/bbigras/trusted
      nurNoPkgs.repos.rycee.hmModules.emacs-init
    ];

    wayland.windowManager.sway = {
      config = {
        input = {
          "1118:1974:Microsoft_Comfort_Curve_Keyboard_3000" = {
            xkb_numlock = "enabled";
          };
        };
      };
    };
  };
}
