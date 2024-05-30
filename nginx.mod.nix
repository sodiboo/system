{
  oxygen.modules = [
    ({config, ...}: {
      networking = {
        firewall.enable = true;
        firewall.allowedTCPPorts = [80 443];

        enableIPv6 = true;
        interfaces.ens18.ipv6.addresses = [
          {
            address = "2a02:c202:2189:7245::1";
            prefixLength = 64;
          }
        ];
      };
      services.nginx = {
        enable = true;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        virtualHosts = let
          base = locations: {
            inherit locations;

            forceSSL = true;
            enableACME = true;
          };
          proxy = port:
            base {
              "/".proxyPass = "http://127.0.0.1:${toString port}/";
              "/".proxyWebsockets = true;
            };
        in {
          "gaysex.cloud" = proxy config.services.sharkey.settings.port;
          "search.gaysex.cloud" = proxy config.services.searx.settings.server.port;
        };
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "acme@sodi.boo";
      };
    })
  ];
}
