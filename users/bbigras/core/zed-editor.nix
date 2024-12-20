{ nixpkgs_zed, lib, ... }:

{
  programs.zed-editor = {
    enable = true;
    # https://github.com/zed-industries/extensions/tree/main/extensions
    extensions = [
      "env"
      "gleam"
      "graphql"
      "helm"
      "just"
      "nix"
      "sql"
      "wakatime"
    ];
    userSettings = {
      theme = {
        dark = lib.mkForce "Catppuccin Macchiato";
      };
    };
  };
}
