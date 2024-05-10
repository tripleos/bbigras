{ hostType, impermanence, nix-index-database, pkgs, lib, catppuccin, ... }:

# let
#perfect_eq_repo = pkgs.fetchgit {
#  url = "https://github.com/JackHack96/EasyEffects-Presets";
#  rev = "041588fa7871b53282221741b3d11593f96ce468";
#  sha256 = "sha256-gpdW2k9E+3DtaztD89wp1TA1kyrAdQNXNFT3hk36WA0=";
#};

# easyeffects-presets_repo = pkgs.fetchgit {
#   url = "https://github.com/Digitalone1/EasyEffects-Presets";
#   rev = "1148788e2768170d704fd2de4f7f5053d32f71d4";
#   sparseCheckout = ''
#     LoudnessEqualizer.json
#   '';
#   sha256 = "sha256-WzfVg7PAfrreKC1ckzVtCfOJ90JaUdl/h5mcXt4SFUw=";
# };

# mic_gist_repo = pkgs.fetchgit {
#   url = "https://gist.github.com/a10225eb132cdcb97d7c458526f93085.git";
#   rev = "5219f20faeaab9ac069cfe93b1d6fbdd82301dfe";
#   sha256 = "sha256-pSjtpKs2nA5fZ85k2N18nzzK5JttUj0ZqxpMEXd+OEs=";
# };

#pipewire_repo = pkgs.fetchgit {
#  url = "https://gitlab.freedesktop.org/pipewire/pipewire.git";
#  rev = "c6ffeeeb342311f9d8b3916447f2001e959f99e6";
#  sha256 = "sha256-frkxyR63frjdOHSF8obOA3NWGyhSKg+yVjlZ1mLlsMY=";
#};
# in
{
  imports = [
    impermanence.nixosModules.home-manager.impermanence
    nix-index-database.hmModules.nix-index
    catppuccin.homeManagerModules.catppuccin

    ./atuin.nix
    ./btop.nix
    ./git.nix
    ./emacs
    ./ssh.nix
    ./tmux.nix
    ./xdg.nix
    ./zsh.nix
  ];

  catppuccin.flavour = "mocha";

  # XXX: Manually enabled in the graphic module
  dconf.enable = false;

  home = {
    username = "bbigras";
    stateVersion = "22.11";
    packages = with pkgs; [
      nix-closure-size
      truecolor-check

      libqalculate

      mosh

      ripgrep

      # dev
      bfg-repo-cleaner
      gitAndTools.git-machete
      git-filter-repo
      git-ps-rs
      gist
      gitAndTools.gh
      colordiff

      # net
      croc

      rclone
      tailscale
      tcpdump
      webwormhole
      xh

      # nix
      cachix
      comma
      manix
      nix-update
      nixpkgs-fmt

      # cool cli tools
      fd
      hexyl
      procs
      pwgen
      sd # find & replace
      bandwhich
      doggo
      btop

      # Android
      # android-studio
      # scrcpy

      # security?
      bitwarden-cli

      # backup
      restic
      # kopia

      # gist gopass  weechat

      # utils
      file
      strace

      # rust
      cargo
      cargo-audit
      cargo-outdated
      # cargo-asm
      # cargo-bloat
      # cargo-crev
      cargo-expand
      cargo-flamegraph
      # cargo-fuzz
      # cargo-geiger
      cargo-sweep
      cargo-tarpaulin
      cargo-udeps


      compsize

      pv

      # asciinema # record the terminal
      docker-compose # docker manager
      ncdu # disk space info (a better du)
      prettyping # a nicer ping

      feh # light-weight image viewer
      killall

      unar
      ntp

      # Go
      # go
      # gopls

      # kubernetes
      k9s
      kdash
      kubectl
      kubectx
      kubelogin-oidc
      # istioctl
      kubernetes-helm
      kind

      # perf
      sysstat

      ventoy
      docker-credential-helpers
      viddy
      natscli
      just

      yt-dlp
      zrok
      aichat
      quickemu
      mediainfo

      git-annex
      git-remote-gcrypt
      qalculate-gtk
      devpod
      open-interpreter
      altair
      broot
      usbimager
    ];
    shellAliases = {
      cls = "clear";
      j = "${pkgs.just}/bin/just";
      ".j" = "${pkgs.just}/bin/just --justfile ~/.user.justfile";
      less = "${pkgs.bat}/bin/bat";
      man = "${pkgs.bat-extras.batman}/bin/batman";
    };
  };

  programs = {
    aria2.enable = true;
    atuin = {
      enable = true;
      settings.auto_sync = true;
    };
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [ batman ];
      catppuccin.enable = true;
    };
    carapace.enable = true;
    eza.enable = true;
    jq.enable = true;
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
      defaultCommand = "fd --type f";
      changeDirWidgetCommand = "fd --type d"; # alt+c
      fileWidgetCommand = "fd --type f";
      catppuccin.enable = true;
    };
    gpg.enable = true;
    navi.enable = true;
    nix-index.enable = true;
    sqls.enable = true;

    bashmount.enable = true;

    rio.enable = true;
    sapling = {
      enable = true;
      userEmail = "bigras.bruno@gmail.com";
      userName = "Bruno Bigras";
    };
    ssh = {
      enable = true;
      hashKnownHosts = true;

      extraOptionOverrides = {
        AddKeysToAgent = "confirm";
        VerifyHostKeyDNS = "ask";
      };
    };
    starship = {
      enable = true;
      catppuccin.enable = true;
    };
    tealdeer.enable = true;
    zoxide.enable = true;
    nushell.enable = false;
    zellij.enable = true;
  };

  services = {
    # spotifyd.enable = true;
    syncthing.enable = true;
    systembus-notify.enable = true;
  };

  # https://github.com/Digitalone1/EasyEffects-Presets
  # xdg.configFile."easyeffects/output/LoudnessEqualizer.json".source = "${easyeffects-presets_repo}/LoudnessEqualizer.json";

  # https://github.com/JackHack96/EasyEffects-Presets
  #xdg.configFile."easyeffects/output/Perfect EQ.json".source = "${perfect_eq_repo}/Perfect EQ.json";
  #xdg.configFile."easyeffects/output/Bass Enhancing + Perfect EQ.json".source = "${perfect_eq_repo}/Bass Enhancing + Perfect EQ.json";
  #xdg.configFile."easyeffects/output/Boosted.json".source = "${perfect_eq_repo}/Boosted.json";
  #xdg.configFile."easyeffects/output/Advanced Auto Gain.json".source = "${perfect_eq_repo}/Advanced Auto Gain.json";

  # xdg.configFile."easyeffects/input/Improved Microphone (Male voices, with Noise Reduction).json".source = "${mic_gist_repo}/Improved Microphone (Male voices, with Noise Reduction).json";

  #xdg.configFile."pipewire/filter-chain.conf.d/sink-virtual-surround-5.1-kemar2.conf".source = "${pipewire_repo}/src/daemon/filter-chain/sink-virtual-surround-5.1-kemar.conf";

  # /home/bbigras/src/virtual-surround/resources/hrir_kemar/hrir-kemar.wav

  # /nix/store/dr1vhsvi39i3nzi3ak4ncrcabqf59m87-pipewire-c6ffeee/src/daemon/filter-chain/sink-virtual-surround-5.1-kemar.conf
  # /nix/store/nb3v25xs49b1aasjqlpywvv58z1iaqyy-pipewire-0.3.56-lib/share/pipewire/filter-chain/sink-virtual-surround-5.1-kemar.conf
  # /nix/store/jh21g751nxpzsyrrw92hryz8p6a0dwaw-pipewire-0.3.56-lib/share/pipewire/filter-chain/sink-virtual-surround-5.1-kemar.conf
  # /nix/store/vs9fqz47mgy9pi4d5znz7c8gg962vrs3-pipewire-0.3.56-lib/share/pipewire/filter-chain/sink-virtual-surround-5.1-kemar.conf

  home.language.base = "fr_CA.UTF-8";

  systemd.user.startServices = "sd-switch";

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
