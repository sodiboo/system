{
  oxygen =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      imports = [ ./caddy ];

      options.caddy.sites = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
            };
          }
        );
        default = { };
      };

      options.caddy.routes = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.listOf config.caddy.lib.types.http.route);
        default = { };
      };

      config = {
        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
          allowedUDPPorts = [
            443
          ];
        };

        caddy = {
          enable = true;

          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/caddy-dns/acmedns@v0.4.1"
            ];

            hash = "sha256-UH8+A+Z25MYX0itxuwey31LMhQmSqb2rJrwCofM6xr8=";
          };

          ports = {
            http = 80;
            https = 443;
          };

          ports-dgram = {
            quic = 443;
          };

          settings =
            let
              all-hosts-for-which-i-serve-https = builtins.attrNames config.caddy.sites;

              default-encode = {
                handler = "encode";
                prefer = [
                  "zstd"
                  "gzip"
                ];
                encodings = {
                  zstd = { };
                  gzip = { };
                };
              };
            in
            {
              admin.disabled = true;

              # zero is "eternal". so, the minimum is one nanosecond.
              apps.http.grace_period = "1ns";

              apps.http.servers.insecure = {
                listen = [ "fd/{env.FD_http}" ];
                listen_protocols = [ [ "h1" ] ];
                automatic_https.disable = true;
                routes = [
                  {
                    match = [ { host = all-hosts-for-which-i-serve-https; } ];
                    terminal = true;
                    handle = [
                      {
                        handler = "static_response";
                        status_code = "308"; # permanent redirect

                        headers.Location = [ "https://{http.request.host}{http.request.orig_uri}" ];
                      }
                    ];
                  }
                ]
                ++ [ { handle = [ default-encode ]; } ]
                ++ config.caddy.routes.unknown;
              };

              apps.http.servers.default = {
                listen = [
                  "fd/{env.FD_https}"
                  "fdgram/{env.FD_quic}"
                ];
                listen_protocols = [
                  [
                    "h1"
                    "h2"
                  ]
                  [
                    "h3"
                  ]
                ];
                automatic_https.disable = true;
                tls_connection_policies = [
                  {
                    # an empty connection policy tells Caddy to, in fact, use TLS, instead of ignoring HTTP/2 and HTTP/3
                  }
                ];

                routes = [
                  { handle = [ default-encode ]; }
                ]
                ++ map (host: {
                  match = [ { host = [ host ]; } ];
                  terminal = true;
                  handle = [
                    {
                      handler = "subroute";
                      inherit (config.caddy.sites.${host}) routes;
                    }
                  ];
                }) all-hosts-for-which-i-serve-https;
              };

              apps.tls = {
                certificates.automate = all-hosts-for-which-i-serve-https;
                automation.policies = [
                  {
                    subjects = all-hosts-for-which-i-serve-https;
                    on_demand = true;
                    issuers = [
                      {
                        module = "acme";
                        email = "acme@sodi.boo";

                        challenges = {
                          http.disabled = true;
                          tls-alpn.disabled = true;

                          dns = {
                            provider = {
                              name = "acmedns";
                              subdomain = "941540cd-efb3-4191-95e9-bd01f534a031";
                              username = config.caddy.lib.mkSecret { file = config.sops.secrets."acme-dns/username".path; };
                              password = config.caddy.lib.mkSecret { file = config.sops.secrets."acme-dns/password".path; };

                              # this *has* to be over localhost, because this is used to provision
                              # the certificate for the public endpoint https://acme.computers.gay/
                              server_url = "http://127.0.0.1:${toString config.services.acme-dns.settings.api.port}/";
                            };

                            resolvers = [
                              "1.1.1.1"
                              "1.0.0.1"
                            ];
                          };
                        };
                      }
                    ];
                  }
                ];
              };
            };
        };

        sops.secrets."acme-dns/username" = { };
        sops.secrets."acme-dns/password" = { };
      };
    };
}
