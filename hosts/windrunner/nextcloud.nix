let
  port = 8000;
  nextcloud_admin_pass = "/etc/nextcloud-admin-pass";
  host_name = "nextcloud.maxrn.dev";
in
{
  services.nextcloud = {
    enable = true;
    database.createLocally = true;
    hostName = host_name;
    config.adminpassFile = nextcloud_admin_pass;
  };

  services.caddy = {
    virtualHosts."${host_name}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };

  sops.secrets.nextcloud_admin_pass = {
    path = nextcloud_admin_pass;
  };
}
