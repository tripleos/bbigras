# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, nur, nixos-hardware, ... }:

let
  nurNoPkgs = import nur { pkgs = null; nurpkgs = pkgs; };
in
rec {
  imports = with nixos-hardware.nixosModules;
    [
      ../../core
      ../../dev

      # Include the results of the hardware scan.
      ../../hardware/hardware-configuration-laptop.nix
      ../../hardware/efi.nix
      ../../hardware/bluetooth.nix
      ../../hardware/sound.nix
      dell-xps-13-9343
      common-hidpi

      ../../graphical
      ../../graphical/sway.nix
      ../../graphical/trusted.nix
      ../../dev/virt-manager.nix

      # ../../dev/rust-embeded.nix
      ../../dev/adb.nix

      ../../users/bbigras
    ] ++ (if builtins.pathExists (builtins.getEnv "PWD" + "/secrets/at_home.nix") then [ (builtins.getEnv "PWD" + "/secrets/at_home.nix") ] else [ ])
    ++ (if builtins.pathExists (builtins.getEnv "PWD" + "/secrets/laptop.nix") then [ (builtins.getEnv "PWD" + "/secrets/laptop.nix") ] else [ ]);

  environment.systemPackages = with pkgs; [
    iwd
    boot.kernelPackages.bcc
  ];

  sops.secrets.restic-laptop-password.sopsFile = ./restic-laptop.yaml;
  sops.secrets.restic-laptop-creds.sopsFile = ./restic-laptop.yaml;
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4hqAgOm8CbtstqYcUwTHHqdXqd3FzwPvQl4YVp9Wec root@laptop";
    masterIdentities = [ "/home/bbigras/.config/age/keys/bbigras.age" ];
  };

  age.generators.wireguard-priv.script = { pkgs, file, ... }: ''
    priv=$(${pkgs.wireguard-tools}/bin/wg genkey)
    ${pkgs.wireguard-tools}/bin/wg pubkey <<< "$priv" > ${lib.escapeShellArg (lib.removeSuffix ".age" file + ".pub")}
    echo "$priv"
  '';

  age.secrets.wireguard = {
    rekeyFile = ./secrets/wg.age;
    generator = "wireguard-priv";
  };

  sops.secrets.yggdrasil-conf.sopsFile = ./restic-laptop.yaml;
  sops.secrets.yggdrasil-conf.owner = config.users.users.yggdrasil.name;

  hardware.brillo.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    # "fs.inotify.max_user_watches" = 524288;
    # "vm.swappiness" = 1;
  };

  networking = {
    useNetworkd = true;
    dhcpcd.enable = false;
    hostName = "laptop"; # Define your hostname.
    networkmanager.enable = false;
    wireless.iwd.enable = true;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "btrfs";
  };

  services.flatpak.enable = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/8e2cf716-7b2f-4c87-a895-1ea6d84d5f65";
      fsType = "btrfs";
      options = [ "subvol=root,compress=zstd,noatime" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/8e2cf716-7b2f-4c87-a895-1ea6d84d5f65";
      fsType = "btrfs";
      options = [ "subvol=nix,compress=zstd,noatime" ];
    };

  fileSystems."/persist" =
    {
      device = "/dev/disk/by-uuid/8e2cf716-7b2f-4c87-a895-1ea6d84d5f65";
      fsType = "btrfs";
      options = [ "subvol=persist,compress=zstd,noatime" ];
      neededForBoot = true;
    };

  # systemd.user.services.mpris-proxy = {
  #   description = "Mpris proxy";
  #   after = [ "network.target" "sound.target" ];
  #   script = "${pkgs.bluez}/bin/mpris-proxy";
  #   wantedBy = [ "default.target" ];
  # };

  services = {
    # fwupd.enable = true;
    tlp = {
      enable = true;
      settings = {
        #CPU_SCALING_GOVERNOR_ON_AC = "ondemand";
        #CPU_SCALING_GOVERNOR_ON_BAT = "conservative";

        #PLATFORM_PROFILE_ON_AC = "performance";
        #PLATFORM_PROFILE_ON_BAT = "low-power";

        DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = [ "bluetooth" "wifi" ];
        DEVICES_TO_ENABLE_ON_AC = [ "bluetooth" "wifi" ];

        DISK_IOSCHED = [ "none" ];

        START_CHARGE_THRESH_BAT0 = 70;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };

  systemd.targets = {
    ac = {
      description = "On AC power";
      unitConfig.DefaultDependencies = false;
    };
    battery = {
      description = "On battery power";
      unitConfig.DefaultDependencies = false;
    };
  };

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${config.systemd.package}/bin/systemctl start battery.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${config.systemd.package}/bin/systemctl stop ac.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${config.systemd.package}/bin/systemctl start ac.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${config.systemd.package}/bin/systemctl stop battery.target"

      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${config.systemd.package}/bin/systemctl --user --machine=bbigras@.host start battery.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${config.systemd.package}/bin/systemctl --user --machine=bbigras@.host stop ac.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${config.systemd.package}/bin/systemctl --user --machine=bbigras@.host start ac.target"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${config.systemd.package}/bin/systemctl --user --machine=bbigras@.host stop battery.target"
    '';
  };

  systemd.services = {
    tailscaled = {
      partOf = [ "ac.target" ];
      wantedBy = [ "ac.target" ];
    };
    dendrite-demo-pinecone.partOf = [ "ac.target" ];
    dendrite-demo-pinecone.wantedBy = [ "ac.target" ];
    yggdrasil.partOf = [ "ac.target" ];
    yggdrasil.wantedBy = [ "ac.target" ];
  };

  systemd.timers = {
    btrbk-home.partOf = [ "ac.target" ];
    btrbk-home.wantedBy = [ "ac.target" ];
    logrotate.partOf = [ "ac.target" ];
    logrotate.wantedBy = [ "ac.target" ];
    systemd-tmpfiles-clean.partOf = [ "ac.target" ];
    systemd-tmpfiles-clean.wantedBy = [ "ac.target" ];
    fstrim.partOf = [ "ac.target" ];
    fstrim.wantedBy = [ "ac.target" ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/iwd"
      "/var/lib/tailscale"
      "/var/log"
      "/var/lib/flatpak"
      "/var/lib/docker"
      "/var/lib/libvirt"
      "/root/.cache/restic"
      # "/var/cache/libvirt"
      #     "/var/lib/bluetooth"
      #     "/var/lib/systemd/coredump"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.bbigras = {
      directories = [
        ".cache/direnv"
        ".cache/mozilla"
        ".cache/nix"
        ".cache/nix-index"
        ".cache/restic"
        ".cache/tealdeer"
        ".cache/wofi"
        ".cache/zsh"
        ".cargo"
        ".config/Bitwarden CLI"
        ".config/discord"
        ".config/kdeconnect"
        ".config/nix"
        ".config/obsidian"
        ".config/sops/age"
        ".config/syncthing"
        ".wrangler/config"
        ".cache/.wrangler"
        ".cache/wine"
        ".cache/emacs"
        ".cache/winetricks"
        ".npm"
        # ".gnupg/private-keys-v1.d"
        ".local/share/atuin"
        ".local/share/data/Mega Limited/MEGAsync"
        ".local/share/df_linux/data/save"
        ".local/share/direnv"
        ".local/share/pantalaimon"
        ".local/share/remmina"
        ".local/share/task"
        ".local/share/zoxide"
        ".local/share/Steam"
        ".local/share/zsh"
        ".mozilla"
        ".steam"
        ".var/app/com.valvesoftware.Steam"
        "Documents"
        "Downloads"
        "Maildir"
        "MEGAsync"
        "Music"
        "Pictures"
        "Videos"
        "dev"
        "matrix-p2p"
        "tmp"
        "src"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
      files = [
        ".authinfo.gpg"
        ".cache/swaymenu-history.txt"
        ".config/cachix/cachix.dhall"
        ".config/remmina/remmina.pref"
        ".kube/config"
        ".zsh_history"
        ".notmuch-config"
        ".local/share/wall.png"
      ];
    };
  };

  home-manager.users.bbigras = {
    imports = [
      ../../users/bbigras/trusted
      nurNoPkgs.repos.rycee.hmModules.emacs-init
    ];

    systemd.user.targets = {
      ac = {
        Unit = {
          Description = "On AC power";
        };
      };
      battery = {
        Unit = {
          Description = "On battery power";
        };
      };
    };

    systemd.user.services = {
      megasync.Unit.PartOf = [ "ac.target" ];
      megasync.Install.WantedBy = [ "ac.target" ];

      syncthing.Unit.PartOf = [ "ac.target" ];
      syncthing.Install.WantedBy = [ "ac.target" ];

      pantalaimon.Unit.PartOf = [ "ac.target" ];
      pantalaimon.Install.WantedBy = [ "ac.target" ];
    };

    systemd.user.services = {
      brightness-ac = {
        Unit = {
          Description = "100% brightness on ac";
          PartOf = [ "ac.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.brillo}/bin/brillo -e -S 100";
        };
        Install = {
          WantedBy = [ "ac.target" ];
        };
      };

      brightness-battery = {
        Unit = {
          Description = "lower brightness on battery";
          PartOf = [ "battery.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.brillo}/bin/brillo -e -S 50";
        };
        Install = {
          WantedBy = [ "battery.target" ];
        };
      };
    };

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };

    wayland.windowManager.sway = {
      config = {
        input = {
          "1:1:AT_Translated_Set_2_keyboard" = {
            repeat_rate = "70";
            xkb_layout = "ca";
          };
          "1739:30381:DLL0665:01_06CB:76AD_Touchpad" = {
            # dwt = "enabled";
            # tap = "enabled";
            # natural_scroll = "enabled";
            # middle_emulation = "enabled";

            accel_profile = "adaptive";
            click_method = "button_areas";
            dwt = "disabled";
            natural_scroll = "enabled";
            scroll_method = "two_finger";
            tap = "enabled";
          };
        };

        output = {
          "*" = {
            scale = "2";
            # bg = "~/Downloads/molly.png fit";
          };
        };
      };
    };
  };

  services.btrbk = {
    instances = {
      home = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve = "48h";
          snapshot_preserve_min = "18h";
          volume = {
            "/mnt/btr_pool" = {
              subvolume = {
                persist = {
                  snapshot_create = "always";
                };
              };
            };
          };
        };
      };
    };
  };

  # Note `lib.mkBefore` is used instead of `lib.mkAfter` here.
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt

    # We first mount the btrfs root to /mnt
    # so we can manipulate btrfs subvolumes.
    mount -o subvol=/ /dev/mapper/enc /mnt

    # While we're tempted to just delete /root and create
    # a new snapshot from /root-blank, /root is already
    # populated at this point with a number of subvolumes,
    # which makes `btrfs subvolume delete` fail.
    # So, we remove them first.
    #
    # /root contains subvolumes:
    # - /root/var/lib/portables
    # - /root/var/lib/machines
    #
    # I suspect these are related to systemd-nspawn, but
    # since I don't use it I'm not 100% sure.
    # Anyhow, deleting these subvolumes hasn't resulted
    # in any issues so far, except for fairly
    # benign-looking errors from systemd-tmpfiles.
    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
      echo "deleting /$subvolume subvolume..."
      btrfs subvolume delete "/mnt/$subvolume"
    done &&
    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/root-blank /mnt/root

    # Once we're done rolling back to a blank snapshot,
    # we can unmount /mnt and continue on the boot process.
    umount /mnt
  '';
}
