{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    dataDir = "/data/urithiru";
  };

  services.caddy = {
    enable = true;
    virtualHosts."abs.maxrn.dev".extraConfig = ''
      reverse_proxy http://localhost:8000
    '';
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./main.pub)
  ];

  system.stateVersion = "24.05";
}
