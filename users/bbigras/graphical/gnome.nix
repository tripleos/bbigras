{ pkgs, lib, ... }:
{
  imports = [
    ./alacritty.nix
  ];

  home = {
    packages = with pkgs; [
      gnome.eog # image viewer
      gnome.gnome-tweaks

      # extensions
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.dash-to-panel
      gnomeExtensions.space-bar
      gnomeExtensions.user-themes
      gnomeExtensions.vitals
    ];
  };

  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      # gpu-context = "wayland";
      vo = "gpu";
      hwdec = "auto";
    };
  };

  dconf.enable = lib.mkForce true;
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };
    "org/gnome/desktop/input-sources" = {
      sources = [ (lib.gvariant.mkTuple [ "xkb" "ca" ]) ];
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "Alacritty.desktop"
        "org.gnome.Nautilus.desktop"
        "org.remmina.Remmina.desktop"
        "emacs.desktop"
        "element-desktop.desktop"
        "discord.desktop"
      ];
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "Vitals@CoreCoding.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
        "dash-to-panel@jderose9.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "space-bar@luchrioh"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
    };
    "org/gnome/desktop/interface" = {
      enable-hot-corners = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      workspace-names = [ "Main" ];
    };
  };

  services = {
    flameshot.enable = true;
    gnome-keyring.enable = true;
    unclutter.enable = true;
  };
}
