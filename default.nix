{ pkgs ? null }:
let
  sources = import ./nix;
  nixus = import sources.nixus { };
  nixos-hardware = import sources.nixos-hardware;
  nixpkgs = if pkgs == null then sources.nixpkgs else pkgs;
in
nixus ({ ... }: {
  defaults = { ... }: { inherit nixpkgs; };
  nodes = {
    # Personal
    desktop = { ... }: {
      enabled = true;
      hasFastConnection = true;
      host = "desktop";
      configuration = ./systems/desktop.nix;
    };

    laptop = { ... }: {
      enabled = true;
      hasFastConnection = true;
      host = "laptop";
      configuration = ./systems/laptop.nix;
    };

    # work
    work = { ... }: {
      enabled = true;
      host = "work";
      configuration = ./systems/work.nix;
    };
  };
})
