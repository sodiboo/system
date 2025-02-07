{
  self,
  picocss,
  ...
}: {
  oxygen.modules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: let
      pico-just-the-css = pkgs.runCommand "pico-just-the-css" {} ''
        mkdir $out && cp -r ${picocss}/css $out
      '';

      # These should match `vps.sodi.boo` DNS records.
      # All other domains are (flattened) CNAMEs to `vps.sodi.boo`.

      oxygen-ipv4 = "85.190.241.69"; # IPv4 is unused here,
      oxygen-ipv6 = "2a02:c202:2189:7245::1"; # But DHCP doesn't give me IPv6.

      rapid-testing = false;
      generated-site = pkgs.callPackage ./nginx/gen.nix {};
      static-root =
        if rapid-testing
        then "/etc/nixos/nginx/result"
        else "${generated-site}";
    in {
      networking = {
        firewall.enable = true;
        firewall.allowedTCPPorts = [80 443];

        enableIPv6 = true;
        defaultGateway6.address = "fe80::1";
        defaultGateway6.interface = "ens18";
        interfaces.ens18.ipv6.addresses = [
          {
            address = oxygen-ipv6;
            prefixLength = 64;
          }
        ];
      };
      services.nginx = {
        enable = true;

        # !!! If you are referencing my config for Sharkey and/or Matrix, !!!
        # !!!               do not underestimate this line.               !!!
        # !!!                                                             !!!
        # !!!                     You need to have it                     !!!
        # !!!         or media uploads won't work for files >10M.         !!!
        clientMaxBodySize = "1G";

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        appendHttpConfig = ''
          map $time_iso8601 $month {
            default "unreachable";
            "~^(?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})T" $m;
          }

          map $month $is_gay {
            default 0;
            "06" 1;
          }

          map $month $isnt_gay {
            default 1;
            "06" 0;
          }

          map $request_uri $is_domain_specific_well_known {
            default "0";
            "~^/.well-known/(discord|acme-challenge)" "1";
          }

          map "$is_gay$is_domain_specific_well_known" $is_gay_redirectable {
            default 0;
            "10" 1;
          }

          map "$isnt_gay$is_domain_specific_well_known" $isnt_gay_redirectable {
            default 0;
            "10" 1;
          }
        '';

        virtualHosts = let
          static = builtins.mapAttrs (path: conf:
            conf
            // {
              extraConfig =
                ''
                  rewrite ^${lib.escapeRegex (lib.removeSuffix "/" path)}(.+)$ $1 break;
                ''
                + conf.extraConfig or "";
            });
          base-http = locations: {
            extraConfig =
              ''
                error_page 502 /.nginx/502.html;
              ''
              + locations.extraConfig or "";
            locations =
              (builtins.removeAttrs locations ["extraConfig"])
              // static {
                "/.nginx/" = {
                  root = static-root;
                  extraConfig = ''
                    try_files /$server_name$uri $uri @picocss;
                  '';
                };
                "@picocss" = {
                  root = "${pico-just-the-css}";
                };
              };
          };
          base = locations:
            base-http locations
            // {
              forceSSL = true;
              enableACME = true;
            };
          proxy' = host: port: {
            proxyPass = "http://${host}:${toString port}";
            proxyWebsockets = true;
          };
          proxy = host: port:
            base {
              "/" = proxy' host port;
            };
          personal-website = inactive: status: redirect: ''
            location = /blog {
              return 301 /blog/;
            }

            location / {
              root ${./sodi.boo/public};
              try_files $uri/index.html $uri.html $uri @picocss;
            }

            if (${inactive}) {
              return ${toString status} https://${redirect}$request_uri;
            }
          '';

          unknown."= /".extraConfig = ''
            rewrite . /.nginx/raw-ip.html last;
          '';
          unused-domains = ["catboy.rocks" "mrrp.ing" "enby.lol" "enby.live" "sodi.lol" "girlcock.party" "yester.gay"];
        in
          builtins.listToAttrs (map (name: {
              inherit name;
              value = base unknown;
            })
            unused-domains)
          // {
            "0-sort-first" = base-http unknown // {rejectSSL = true;};
            "sodi.boo" = base {
              "= /.well-known/discord".alias = ./sodi.boo/discord-domain-verification;
              extraConfig = personal-website "$is_gay_redirectable" 307 "sodi.gay";
            };
            "sodi.gay" = base {
              extraConfig = personal-website "$isnt_gay_redirectable" 307 "sodi.boo";
            };
            "cache.sodi.boo" = proxy "iridium.wg" self.nixosConfigurations.iridium.config.services.nix-serve.port;
            "gaysex.cloud" =
              base {
                "/" = proxy' "127.0.0.1" config.services.sharkey.settings.port;
                "/_matrix" = proxy' "127.0.0.1" config.services.matrix-conduit.settings.global.port;
              }
              // {
                listen = let
                  l = addr: port: ssl: {inherit addr port ssl;};
                  p = port: ssl: [
                    (l "0.0.0.0" port ssl)
                    (l "[::0]" port ssl)
                  ];
                in
                  p 80 false ++ p 443 true ++ p 8448 true;
              };
            "vpn.sodi.boo" = base {
              "/" = proxy' "127.0.0.1" config.services.headscale.port;
              "/metrics".proxyPass = "http://${config.services.headscale.settings.metrics_listen_addr}/metrics";
            };
            "infodumping.place" = proxy "127.0.0.1" config.services.writefreely.settings.server.port;
            "search.gaysex.cloud" = proxy "127.0.0.1" config.services.searx.settings.server.port;
          };
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "acme@sodi.boo";
      };
    })
  ];
}
