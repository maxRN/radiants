{
  fileSystems."/mnt/ssh" = {
    device = "u462951@u462951.your-storagebox.de";
    fsType = "sshfs";
    options = [
      "nodev"
      "noatime"
      "allow_other"
      "IdentityFile=/etc/ssh/id_host_ed25519"
    ];
  };
}
