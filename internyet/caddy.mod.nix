{
  nitrogen =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      imports = [ ../web/caddy ];

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

          # package = pkgs.caddy.withPlugins {
          #   plugins = [
          #     "github.com/caddy-dns/acmedns@v0.4.1"
          #   ];

          #   hash = "sha256-UH8+A+Z25MYX0itxuwey31LMhQmSqb2rJrwCofM6xr8=";
          # };

          ports = {
            http = 80;
            https = 443;
          };

          ports-dgram = {
            quic = 443;
          };

          settings =
            let
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
                    match = [ { host = ["*.sodiboo.p.nyet" "*.bazed.g.nyet" "*.total-anarchy.g.nyet"]; } ];
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
                }) (builtins.attrNames config.caddy.sites)
                ++ config.caddy.routes.unknown;
              };

              apps.tls.certificates.load_pem = [
                {
                  certificate = builtins.readFile ./server.crt;
                  key = config.caddy.lib.mkSecret { file = config.sops.secrets."internyet-server-key".path; };
                }
                {
                  certificate = builtins.readFile ./bazed.crt;
                  key = config.caddy.lib.mkSecret { file = config.sops.secrets."bazed-key".path; };
                }
                {
                  certificate = builtins.readFile ./total-anarchy.crt;
                  key = config.caddy.lib.mkSecret { file = config.sops.secrets."total-anarchy-key".path; };
                }
              ];
            };
        };

        sops.secrets."internyet-server-key".sopsFile = ./secrets.yaml;
        sops.secrets."bazed-key".sopsFile = ./secrets.yaml;
        sops.secrets."total-anarchy-key".sopsFile = ./secrets.yaml;
      };
    };
}
