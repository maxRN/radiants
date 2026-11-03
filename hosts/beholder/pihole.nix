# Pi-hole as it ran on Raspbian (v6.5, settings marked "### CHANGED" in
# /etc/pihole/pihole.toml as of 2026-10-27). DHCP stays with the router (UniFi Express).
{ config, lib, pkgs, ... }:
let
  # Regex allowlist (domainlist type 2), each covering the domain and all its subdomains.
  # HaGeZi blocks ||sentry.io^ and ||sentry-cdn.com^, which breaks error reporting in apps
  # and sites (and the browser SDK's loader on js.sentry-cdn.com).
  allowRegex = [
    ''(\.|^)sentry\.io$''
    ''(\.|^)sentry-cdn\.com$''
  ];

  # The module only manages list URLs, so own the rows commented "nix" in gravity.db:
  # drop the ones no longer listed, add the rest.
  quote = s: "'${lib.replaceStrings [ "'" ] [ "''" ] s}'";
  syncAllowlist = pkgs.writeShellScript "pihole-sync-allowlist" ''
    exec ${lib.getExe config.services.pihole-ftl.package} sqlite3 \
      ${config.services.pihole-ftl.settings.files.gravity} <<'SQL'
    DELETE FROM domainlist WHERE type = 2 AND comment = 'nix'
      AND domain NOT IN (${lib.concatMapStringsSep ", " quote allowRegex});
    ${lib.concatMapStrings (r: ''
      INSERT OR IGNORE INTO domainlist (type, domain, comment) VALUES (2, ${quote r}, 'nix');
    '') allowRegex}
    SQL
  '';
in
{
  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    queryLogDeleter.enable = true;
    lists = [
      {
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        description = "HaGeZi Multi PRO";
      }
    ];
    settings = {
      dns = {
        # Unbound, which forwards over DNS-over-TLS (unbound.nix).
        upstreams = [ "127.0.0.1#5335" ];
        domainNeeded = true;
        expandHosts = true;
        interface = "eth0";
        listeningMode = "ALL";
        rateLimit.count = 3000;
        # Static leases for these live on the UniFi Express (Home DHCP range .30-.254).
        hosts = [
          "10.10.0.1 unifi.internal"
          "10.10.0.4 beholder.internal"
          "10.10.0.4 pi.hole"
          "10.10.10.2 pc.max.internal"
          "10.10.10.3 pc.anni.internal"
        ];
      };
      webserver.headers = [
        "Content-Security-Policy: default-src 'self' 'unsafe-inline';"
        "X-Frame-Options: DENY"
        "X-XSS-Protection: 0"
        "X-Content-Type-Options: nosniff"
        "Referrer-Policy: strict-origin-when-cross-origin"
      ];
    };
  };

  # Setup runs after FTL and rebuilds gravity.db (minutes on the Pi 3); FTL keeps the stale
  # backup open until told to reload, so nothing gets blocked after a reboot. StopPost, because
  # setup exits 1 on every run (re-adding the existing list fails) though gravity is fine.
  # First sync the allowlist, as the service's own pihole user, so the reload picks it up.
  systemd.services.pihole-ftl-setup.serviceConfig.ExecStopPost = [
    "-${syncAllowlist}"
    "-+${pkgs.systemd}/bin/systemctl kill -s RTMIN pihole-ftl.service"
  ];

  services.pihole-web = {
    enable = true;
    ports = [ "80" ];
  };
}
