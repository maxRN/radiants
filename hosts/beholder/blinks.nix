# blinks link inbox, published on the tailnet as the Tailscale Service svc:blinks
# (https://blinks.diplodocus-barley.ts.net). Same unit as on Raspbian, so the
# state dir (/var/lib/private/blinks) carries over as is.
#
# /etc/blinks/env (BLINKS_PASSWORD, BLINKS_API_KEY) is copied over by hand, not
# managed here. Move it to sops once beholder's host key exists.
{
  config,
  lib,
  pkgs,
  blinks,
  ...
}:
let
  port = 8082;
in
{
  systemd.services.blinks = {
    description = "blinks link inbox";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      BLINKS_ADDR = "127.0.0.1:${toString port}";
      BLINKS_DB_PATH = "/var/lib/blinks/blinks.db";
      BLINKS_TIMEZONE = "Europe/Berlin";
    };
    serviceConfig = {
      ExecStart = lib.getExe blinks.packages.${pkgs.stdenv.hostPlatform.system}.default;
      EnvironmentFile = "/etc/blinks/env";
      DynamicUser = true;
      StateDirectory = "blinks";
      Restart = "on-failure";
      RestartSec = 5;

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
    };
  };

  # HTTPS on the tailnet, plain HTTP to blinks. Not services.tailscale.serve:
  # with tailscale 1.98 the config file's target scheme sets both sides, so
  # "http://" serves plain HTTP on 443 and "https://" talks TLS to blinks.
  # Re-running the command is a no-op. Hosting svc:blinks needs the node's
  # tag:pi, which came with the copied tailscaled state.
  systemd.services.tailscale-serve-blinks = {
    description = "Publish blinks as the Tailscale Service svc:blinks";
    after = [
      "tailscaled.service"
      "tailscaled-set.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe config.services.tailscale.package} serve --service=svc:blinks --https=443 --bg http://127.0.0.1:${toString port}";
      # tailscaled may not be connected yet right after boot.
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
