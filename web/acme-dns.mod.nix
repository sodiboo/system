{
  oxygen =
    { config, ... }:
    let
      domain = "acme.computers.gay";
      zone-admin = "acme.sodi.boo"; # this is an email address: "acme@sodi.boo"
      api-port = 5353;
    in
    {
      caddy.sites.${domain}.routes = [
        {
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [ { dial = "127.0.0.1:${config.services.acme-dns.settings.api.port}"; } ];
            }
          ];
        }
      ];

      services.acme-dns = {
        enable = true;

        settings = {
          api = {
            listen = "127.0.0.1";
            port = api-port;
            tls = "none";
            use_header = true;
            header_name = "X-Forwarded-For";

            disable_registration = true;
          };

          general = {
            listen = "[::]:53";
            protocols = "both";

            domain = domain;
            nsname = domain;
            nsadmin = zone-admin;

            records = [
              "${domain}. A ${config.public-ipv4}"
              "${domain}. AAAA ${config.public-ipv6}"
              "_acme-challenge.${domain}. CNAME acme.sodi.boo."
              "${domain}. NS ${domain}."
            ];
          };
        };
      };

      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 53 ];
    };
}
