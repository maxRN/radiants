{ config, ... }:
{
  fileSystems."/mnt/ssh" = {
    device = "u462951@u462951.your-storagebox.de:/";
    fsType = "sshfs";
    options = [

      "nodev" # Prevents device files from being interpreted on this filesystem (security) (source: claude)
      "noatime" # Doesn't update access times when files are read (performance optimization) (source: claude)

      "allow_other" # for non-root access
      "_netdev" # this is a network fs
      # "x-systemd.automount" # mount on demand
      "X-mount.group=${config.users.groups.networker.name}"

      # SSH options
      "reconnect" # handle connection drops
      "ServerAliveInterval=15" # keep connections alive
      "IdentityFile=/etc/ssh/ssh_host_ed25519_key"
    ];
  };
}
