# Pi-hole as it ran on Raspbian (v6.5, settings marked "### CHANGED" in
# /etc/pihole/pihole.toml as of 2026-10-27). DHCP stays with the router (UniFi Express).
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
        # Static leases for these live on the UniFi Express (DHCP range .100-.254).
        hosts = [
          "10.10.0.1 unifi.internal"
          "10.10.0.2 edge.internal"
          "10.10.0.4 beholder.internal"
          "10.10.0.4 pi.hole"
          "10.10.0.55 pc.max.internal"
          "10.10.0.92 mbp.internal"
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
