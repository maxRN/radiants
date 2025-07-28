{
  lib,
  config,
  ...
}:
with lib;
let
  # Shorter name to access final settings a
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.storagebox;
in
{
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.storagebox = {
    enable = mkEnableOption "Hetzner storagebox";
    members = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "What users need access to the network drive.";
    };
    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/ssh";
      description = "Path on your file system where to mount the storage box.";
    };
    user = mkOption {
      type = types.str;
      default = "u462951";
      description = "The user account of the storage box";
    };
    url = mkOption {
      type = types.str;
      default = "u462951.your-storagebox.de";
      description = "The url of the storagebox";
    };
    boxPath = mkOption {
      type = types.str;
      default = "/";
      description = "The location on the storagebox which to mount to";
    };
    sshKey = mkOption {
      type = types.str;
      default = "/etc/ssh/ssh_host_ed25519_key";
      description = "The private SSH key used for authenticating to the box";
    };
  };

  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {
    fileSystems.${cfg.mountPoint} = {
      device = "${cfg.user}@${cfg.url}:${cfg.boxPath}";
      fsType = "sshfs";
      options = [

        "nodev" # Prevents device files from being interpreted on this filesystem (security) (source: claude)
        "noatime" # Doesn't update access times when files are read (performance optimization) (source: claude)

        "allow_other" # for non-root access
        "_netdev" # this is a network fs
        # "x-systemd.automount" # mount on demand
        "gid=${toString config.users.groups.networker.gid}"

        # SSH options
        "reconnect" # handle connection drops
        "ServerAliveInterval=15" # keep connections alive
        "IdentityFile=${cfg.sshKey}"
      ];
    };
  };

  users.groups.networker = {
    members = cfg.members;
    gid = 990;
  };

}
