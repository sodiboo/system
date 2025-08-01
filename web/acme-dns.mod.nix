{
  oxygen =
    { config, ... }:
    let
      domain = "acme.computers.gay";
      zone-admin = "acme.sodi.boo"; # this is an email address: "acme@sodi.boo"
      api-port = 5353;
    in
    {
      reverse-proxy.${domain}.locations."/".localhost.port = api-port;
      services.acme-dns = {
        enable = true;

        settings = {
          api = {
            listen = "127.0.0.1";
            port = api-port;
            tls = "none";
            use_header = true;
            header_name = "X-Forwarded-For";
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
              "${domain}. NS ${domain}."
            ];
          };
        };
      };

      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 53 ];
    };
}
