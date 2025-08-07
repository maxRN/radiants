{ config, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  sops.secrets.tailscale_auth_key = {
    path = "/etc/nixos/tailscale/auth_key";
  };
}
