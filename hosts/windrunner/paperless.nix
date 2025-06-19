let
  port = 28981;
in
{
  services.paperperless = {
    enable = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."paperless.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };
}
