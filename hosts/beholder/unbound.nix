# Pi-hole's upstream: a local Unbound that forwards over DNS-over-TLS, so the ISP
# can neither read nor rewrite the LAN's queries. Only on localhost, next to FTL's :53.
{
  services.unbound = {
    enable = true;
    # The Pi's own resolv.conf stays on the public resolvers, see networking.nameservers.
    resolveLocalQueries = false;
    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        port = 5335;
        access-control = [ "127.0.0.0/8 allow" ];
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        # Pi-hole caches already; keep Unbound small on the Pi 3's 1 GB.
        msg-cache-size = "8m";
        rrset-cache-size = "16m";
        num-threads = 1;
        # No subnet hints to upstream, and minimal query names.
        qname-minimisation = true;
        hide-identity = true;
        hide-version = true;
        prefetch = true;
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          # ip@port#tls-name; the name is checked against the server's certificate.
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
        }
      ];
    };
  };
}
