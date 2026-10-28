# Raspberry Pi 3B (1 GB RAM): LAN DNS via Pi-hole on 192.168.1.4.
#
# Too little RAM to evaluate its own config, so it's always built elsewhere
# (ohnezahn's linux-builder) and deployed with ./deploy.sh. Imports the stock
# aarch64 SD image module, so the same config also yields the image to flash:
#   nix build .#packages.aarch64-linux.beholder-sd-image
{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ../shared.nix
    ./pihole.nix
    ./blinks.nix
  ];

  # Ship the image uncompressed so it can be dd'd directly.
  sdImage.compressImage = false;

  # The onboard NIC hangs off USB, so its predictable name would be path-based
  # (enu1u1u1 or similar). Keep eth0, which pihole's dns.interface refers to too.
  networking.usePredictableInterfaceNames = false;

  networking = {
    hostName = "beholder";
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.4";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eth0";
    };
    # Not itself: the Pi must resolve even when pihole-FTL is down.
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    firewall.enable = true;
  };

  # No auth key: /var/lib/tailscale is copied over from the Raspbian install, so
  # the node keeps its identity, tag:pi and tailnet IP (100.121.63.92).
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Keep 100.100.100.100 out of /etc/resolv.conf, see networking.nameservers.
    extraSetFlags = [ "--accept-dns=false" ];
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Reachable on the LAN too, for when tailscale is down.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../kaladin/main.pub)
    (builtins.readFile ../kaladin/ohnezahn.pub)
  ];

  # Decrypted with the host key; its age recipient is &beholder in .sops.yaml.
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  zramSwap.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.dig
    pkgs.neovim
    pkgs.sqlite
  ];

  system.stateVersion = "26.05";
}
