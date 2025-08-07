{ paperless-pkgs, config, ... }:
let
  config_file = "/var/lib/config-paperless/config";
  password_file = "/var/lib/config-paperless/passwd";
in
# make sure to `tailscale serve 28981`
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

  services.storagebox.members = [ config.services.paperless.user ];

  sops.secrets.paperless_config = {
    path = config_file;
  };
  sops.secrets.paperless_password = {
    path = password_file;
  };
}
