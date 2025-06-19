let
  port = 5000;
in
{
  services.changedetection-io = {
    enable = true;
    port = port;
    behindProxy = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."change.maxrn.dev".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };
}
