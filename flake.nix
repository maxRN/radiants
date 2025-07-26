{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    paperless-pkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      rev = "bdac72d387dca7f836f6ef1fe547755fb0e9df61";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      disko,
      sops-nix,
      paperless-pkgs,
      ...
    }:
    {
      nixosConfigurations.windrunner = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          nixpkgs-stable = import nixpkgs-stable { inherit system; };
          paperless-pkgs = import paperless-pkgs { inherit system; };
        };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/windrunner
        ];
      };

    };
}
