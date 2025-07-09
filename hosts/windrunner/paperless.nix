{ pkgs, config, ... }:
let
  port = 28981;
in
{
  services.paperless = {
    enable = true;
    consumptionDir = "/var/lib/maestral";
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

  systemd.services = {
    paperless-maestral-integration = {
      path = [
        pkgs.curl
      ];
      script = ''
        #!${pkgs.bash}/bin/bash
        echo moving files...
        mv /root/dropbox/paperless/* /var/lib/paperless/consume || true # don't care if no files were found
        echo moved file
      '';
      serviceConfig = {
        User = config.users.users.root.name;
      };
      # startAt is special syntax which automatically creates a service file and a timer for that service file
      startAt = "*:*"; # every minute
    };
  };

}
