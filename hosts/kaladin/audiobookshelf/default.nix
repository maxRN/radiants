{ config, ... }:
let
  port = 8000;
in
{

  imports = [ ./refreshToken.nix ];

  services.audiobookshelf.enable = true;
  services.audiobookshelf.REFRESH_TOKEN_EXPIRY = 42 * 24 * 60 * 60; # 42 days

  services.caddy = {
    virtualHosts."abs.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };

  services.storagebox.members = [ config.services.audiobookshelf.user ];
}
