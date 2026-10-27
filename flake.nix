{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    paperless-pkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # beholder's own channel: stable for a DNS box, and new enough for services.tailscale.serve.
    nixpkgs-beholder.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Private repo with an unpushed branch, so the local checkout. beholder is only
    # ever built on ohnezahn anyway.
    blinks = {
      url = "git+file:///Users/maxrn/code/blinks?ref=listen-addr";
      inputs.nixpkgs.follows = "nixpkgs-beholder";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      disko,
      sops-nix,
      paperless-pkgs,
      nixpkgs-beholder,
      blinks,
      ...
    }:
    {
      nixosConfigurations.kaladin = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
          nixpkgs-stable = import nixpkgs-stable { inherit system; };
          paperless-pkgs = import paperless-pkgs { inherit system; };
        };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/kaladin
        ];
      };

      nixosConfigurations.beholder = nixpkgs-beholder.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit blinks; };
        modules = [ ./hosts/beholder ];
      };

      packages.aarch64-linux.beholder-sd-image = self.nixosConfigurations.beholder.config.system.build.sdImage;
    };
}
