{
  inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-beholder";
    };
    # beholder's own channel: stable for a DNS box, and new enough for services.tailscale.serve.
    nixpkgs-beholder.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Private repo with an unpushed branch, so the local checkout. beholder is only
    # ever built on ohnezahn anyway.
    blinks = {
      url = "git+file:///Users/maxrn/code/blinks?ref=listen-addr";
      inputs.nixpkgs.follows = "nixpkgs-beholder";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-beholder";
    };
    # Needs the Rex package token in ohnezahn's /etc/nix/netrc until the first release.
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-beholder";
    };
  };
  outputs =
    {
      self,
      sops-nix,
      nixpkgs-beholder,
      blinks,
      home-manager,
      rex,
      ...
    }:
    {
      nixosConfigurations.beholder = nixpkgs-beholder.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit blinks rex; };
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ./hosts/beholder
        ];
      };

      packages.aarch64-linux.beholder-sd-image = self.nixosConfigurations.beholder.config.system.build.sdImage;
    };
}
