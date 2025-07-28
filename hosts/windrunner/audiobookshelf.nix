{ config, ... }:
let
  port = 8000;
in
{
  services.audiobookshelf.enable = true;

  services.caddy = {
    virtualHosts."abs.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };

  services.storagebox.members = [ config.services.audiobookshelf.user ];
}
