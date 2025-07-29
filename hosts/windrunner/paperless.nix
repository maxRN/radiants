{ paperless-pkgs, config, ... }:
let
  port = 28981;
  config_file = "/var/lib/config-paperless/config";
  password_file = "/var/lib/config-paperless/passwd";
in
{
  services.paperless = {
    enable = true;
    package = paperless-pkgs.paperless-ngx;
    consumptionDir = "/var/lib/maestral/paperless";
    environmentFile = config_file;
    passwordFile = password_file;
    dataDir = config.services.storagebox.mountPoint + "/paperless";
    settings = {
      PAPERLESS_URL = "https://paperless.maxrn.dev";
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."paperless.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };

  services.storagebox.members = [ config.services.paperless.user ];

  sops.secrets.paperless_config = {
    path = config_file;
  };
  sops.secrets.paperless_password = {
    path = password_file;
  };
}
