{
  systems,
  picocss,
  ...
}:
{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      pico-just-the-css = pkgs.runCommand "pico-just-the-css" { } ''
        mkdir $out && cp -r ${picocss}/css $out
      '';

      rapid-testing = false;
      generated-site = pkgs.callPackage ./nginx/gen.nix { };
      static-root = if rapid-testing then "/etc/nixos/nginx/result" else "${generated-site}";
    in
    {
      networking = {
        firewall.enable = true;
        firewall.allowedTCPPorts = [
          80
          443
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

        virtualHosts =
          let
            static = builtins.mapAttrs (
              path: conf:
              conf
              // {
                extraConfig = ''
                  rewrite ^${lib.escapeRegex (lib.removeSuffix "/" path)}(.+)$ $1 break;
                ''
                + conf.extraConfig or "";
              }
            );

            scaffold = {
              locations = {
                "^~ /.nginx/" = {
                  root = static-root;
                  tryFiles = "/$server_name$uri $uri @picocss";
                  extraConfig = ''
                    rewrite ^/\.nginx(.+)$ $1 break;
                  '';
                };
                "@picocss".root = "${pico-just-the-css}";
              };

              extraConfig = ''
                error_page 502 /.nginx/502.html;
              '';
            };

            acme = {
              forceSSL = true;
              enableACME = true;
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

            unknown.locations."= /".extraConfig = ''
              rewrite . /.nginx/raw-ip.html last;
            '';
            unused-domains = [
              "catboy.rocks"
              "mrrp.ing"
              "enby.lol"
              "enby.live"
              "sodi.lol"
              "girlcock.party"
              "yester.gay"
              "infodumping.place"
            ];
          in
          lib.mkMerge ([
            {
              _ = lib.mkMerge [
                scaffold
                unknown
                {
                  # default = true;
                  rejectSSL = true;
                }
              ];
            }
            (lib.genAttrs unused-domains (
              lib.const (
                lib.mkMerge [
                  scaffold
                  acme
                  unknown
                ]
              )
            ))
            {
              "sodi.boo" = lib.mkMerge [
                scaffold
                acme
                {
                  locations."= /.well-known/discord".alias = ./sodi.boo/discord-domain-verification;
                  extraConfig = personal-website "$is_gay_redirectable" 307 "sodi.gay";
                }
              ];
              "sodi.gay" = lib.mkMerge [
                scaffold
                acme
                {
                  extraConfig = personal-website "$isnt_gay_redirectable" 307 "sodi.boo";
                }
              ];
            }
            (builtins.mapAttrs (
              _name: cfg:
              lib.mkMerge [
                scaffold
                acme
                {
                  locations = (
                    builtins.mapAttrs (loc: cfg: {
                      proxyPass = cfg.url;
                      proxyWebsockets = true;
                    }) cfg.locations
                  );

                  listen =
                    let
                      l = addr: port: ssl: { inherit addr port ssl; };
                      p = ssl: port: [
                        (l "0.0.0.0" port ssl)
                        (l "[::0]" port ssl)
                      ];

                      http = p false;
                      https = p true;
                    in
                    builtins.concatLists ([ (http 80) ] ++ map https ([ 443 ] ++ cfg.extra-public-ports));
                }
              ]
            ) config.reverse-proxy)
          ]);
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "acme@sodi.boo";
      };
    };
}
