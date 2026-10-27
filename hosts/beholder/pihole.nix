# Pi-hole as it ran on Raspbian (v6.5, settings marked "### CHANGED" in
# /etc/pihole/pihole.toml as of 2026-10-27). DHCP stays with the router.
{
  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    queryLogDeleter.enable = true;
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        description = "Steven Black's unified adlist";
      }
    ];
    settings = {
      dns = {
        upstreams = [
          "8.8.8.8"
          "8.8.4.4"
          "208.67.222.222"
          "208.67.220.220"
        ];
        domainNeeded = true;
        expandHosts = true;
        interface = "eth0";
        listeningMode = "ALL";
        rateLimit.count = 3000;
        hosts = [
          "192.168.1.4 beholder.internal"
          "192.168.1.4 pi.hole"
          "192.168.1.53 wifi.internal"
          "192.168.1.55 pc.max.internal"
          "192.168.1.1 edge.internal"
          "192.168.178.1 fritz.internal"
          "192.168.1.92 mbp.internal"
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

  services.pihole-web = {
    enable = true;
    ports = [ "80" ];
  };
}
