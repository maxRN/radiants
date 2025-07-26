{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
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
      ...
    }:
    {
      nixosConfigurations.windrunner = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          nixpkgs-stable = import nixpkgs-stable { inherit system; };
        };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/windrunner
        ];
      };

    };
}
