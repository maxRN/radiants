{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    # paperless-pkgs = {
    #   type = "github";
    #   owner = "nixos";
    #   repo = "nixpkgs";
    #   rev = "6b4955211758ba47fac850c040a27f23b9b4008f";
    # };
    paperless-pkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
