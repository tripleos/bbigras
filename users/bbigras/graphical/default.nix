{ hostType, pkgs, ... }: {
  imports = [
    (
      if hostType == "nixos" || hostType == "homeManager" then ./linux.nix
      else if hostType == "darwin" then ./darwin.nix
      else throw "Unknown hostType '${hostType}' for users/bbigras/graphical"
    )
    ./alacritty.nix
    ./kitty.nix
  ];

  home.packages = with pkgs; [
    element-desktop
    libnotify
    qalculate-gtk
    xdg-utils

    google-chrome
    remmina


    # media
    pavucontrol

    # games
    # lutris

    # twitch
    # streamlink
    chatterino2

    qbittorrent
    wireshark

    # games
    # starsector
    mangohud
    # heroic

    dbeaver
    josm


    # remote
    anydesk
    rustdesk

    # anytype

    joplin-desktop
    # megasync

    xournalpp
    space-station-14-launcher

  ] ++ lib.filter (lib.meta.availableOn stdenv.hostPlatform) [
    discord
    # iterm2
    # ledger-live-desktop
    # plexamp
    # signal-desktop
    # thunderbird
  ];

  services = {
    # megasync.enable = true;
    # kdeconnect.enable = true;
  };
}
