{ config, ... }:
let
  encryption_key_file = "/var/lib/config-pocket-id/encryption_key";
  port = 1411;
in
{
  services.pocket-id.enable = true;
  services.pocket-id.settings = {
    TRUST_PROXY = true;
    APP_URL = "https://auth.maxrn.dev";
    ENCRYPTION_KEY_FILE = encryption_key_file;
  };

  sops.secrets.pocket-id_encryption = {
    path = encryption_key_file;
    owner = config.services.pocket-id.user;
    group = config.services.pocket-id.group;
  };

  services.caddy = {
    virtualHosts."auth.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };

}
