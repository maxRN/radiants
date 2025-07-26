{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}:
let
  smb_secrets = "/etc/nixos/smb-secrets";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./audiobookshelf.nix
    ./changedetection.nix
    ./paperless.nix
    ./maestral.nix
    ../shared.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  services.caddy = {
    enable = true;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.cifs-utils
    pkgs.ffmpeg
    pkgs.id3v2
    pkgs.neovim
  ];

  fileSystems."/mnt/share" = {
    device = "//u462951.your-storagebox.de/backup";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [
        "${automount_opts},credentials=${smb_secrets},gid=${config.users.groups.networker.gid}"
      ];
  };

  users.groups.networker.members = [ config.services.audiobookshelf.user ];

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./main.pub)
    (builtins.readFile ./ohnezahn.pub)
  ];

  system.stateVersion = "24.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;
  # This is the actual specification of the secrets.
  sops.secrets.storagebox_credentials = {
    path = smb_secrets;
  };

}
