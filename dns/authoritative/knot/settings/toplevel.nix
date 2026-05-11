{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./sparse-submodule.nix
    ./nonempty-str.nix
    ./acl.nix
    ./tsig.nix
    ./remote.nix
    ./generic.nix
    ./templates.nix
    ./server.nix
    ./zones.nix
  ];

  options._module.render = lib.mkOption {
    type = lib.types.functionTo (
      lib.types.submodule {
        options = {
          main-phase = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          zone-phases = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            default = { };
          };

          notify-phase = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
  };

  options.rendered = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
  };

  config.rendered =
    pkgs.runCommand "knot.conf"
      {
        outputs = [
          "out"
          "zones"
        ];
      }
      ''
        mkdir storage
        mkdir rundir

        mkdir $zones
        mkdir $zones/catalog

        ${
          let
            chronic = "${lib.getExe' pkgs.moreutils "chronic"}";
            knotc = "${lib.getExe' pkgs.knot-dns "knotc"} --confdb storage/confdb";
            knotc-ctl = args: "${knotc} --socket ./rundir/knot.sock ${lib.escapeShellArgs args}";
            knotc' = knotc-ctl;
            # knotc' = args: "${chronic} ${knotc-ctl args}";
          in
          ''
            ${knotc} conf-import ${builtins.toFile "daemon.conf" ''
              server:
                rundir: ./rundir
                async-start: on
              database:
                storage: ./storage
              log:
                - target: stderr
                  any: notice
                - target: daemon.log
                  any: error
            ''}
            ${lib.getExe' pkgs.knot-dns "knotd"} --confdb storage/confdb &

            while [ ! -e ./rundir/knot.sock ]
            do
              sleep 0.1
            done

            ${knotc' [ "conf-begin" ]}
            ${knotc' [
              "conf-unset"
              "server.rundir"
            ]}
            ${knotc' [
              "conf-set"
              "log[daemon.log].any"
              "warning" # set late, supress initial warnings "no zones, no interfaces"
            ]}
            ${knotc' [ "conf-commit" ]}

            ${
              let
                inherit (config._module.render knotc') main-phase zone-phases notify-phase;
              in

              builtins.concatStringsSep "\n" (
                lib.optionals (main-phase != [ ]) (
                  [ (knotc' [ "conf-begin" ]) ] ++ main-phase ++ [ (knotc' [ "conf-commit" ]) ]
                )
                ++ builtins.concatLists (
                  builtins.attrValues (
                    builtins.mapAttrs (
                      zone: zone-phase:
                      lib.optionals (zone-phase != [ ]) (
                        [
                          (knotc' [
                            "zone-begin"
                            zone
                          ])
                        ]
                        ++ zone-phase
                        ++ [
                          (knotc' [
                            "zone-commit"
                            zone
                          ])
                        ]
                      )
                    ) zone-phases
                  )
                )
                ++ lib.optionals (notify-phase != [ ]) (
                  [ (knotc' [ "conf-begin" ]) ] ++ notify-phase ++ [ (knotc' [ "conf-commit" ]) ]
                )
              )
            }


            ${knotc' [ "stop" ]}
            wait $!
            ${knotc} conf-check
            ${knotc} zone-check
            mkdir $out
            ${knotc} conf-export $out/knot.conf
            ${knotc} conf-export +schema $out/schema.json
          ''
        }

        ln -s $zones $out/zones
        mv storage $out/storage

        if cat daemon.log | grep critical >/dev/null; then
          exit 1;
        elif cat daemon.log | grep error >/dev/null; then
          exit 1;
        elif cat daemon.log | grep warning >/dev/null; then
          echo "warning emitted; refusing to continue"
          exit 1;
        fi
      '';

  # options.rendered-with-stub-secrets = lib.mkOption {
  #   type = lib.types.raw;
  #   readOnly = true;
  #   default = config._module.render { stub-secrets = true; };
  # };

  # options.lib.types.secret = lib.mkOption {
  #   type = lib.types.optionType;
  #   readOnly = true;
  #   default = lib.mkOptionType {
  #     name = "knot-secret";
  #     description = "knot secret";
  #     descriptionClass = "noun";

  #     check = lib.isType "knot-secret";
  #     merge =
  #       (lib.types.submodule {
  #         options = {
  #           _type = lib.mkOption { type = lib.types.enum [ "knot-secret" ]; };
  #           file = lib.mkOption {
  #             type = lib.types.addCheck (lib.types.pathWith { inStore = false; }) (
  #               path: !(builtins.hasContext path)
  #             );
  #           };
  #         };
  #       }).merge;
  #   };
  # };

  # options.lib.mkSecret = lib.mkOption {
  #   type = lib.types.functionTo config.lib.types.secret;
  #   readOnly = true;
  #   default = lib.setType "knot-secret";
  # };

  # options.lib.secrets-impl =
  #   let
  #     scrub =
  #       let
  #         recursively-get-all-secret-paths =
  #           item:
  #           if lib.isType "knot-secret" item then
  #             [ item.file ]
  #           else if lib.isDerivation item then
  #             [ ]
  #           else if builtins.isAttrs item then
  #             builtins.concatMap recursively-get-all-secret-paths (builtins.attrValues item)
  #           else if builtins.isList item then
  #             builtins.concatMap recursively-get-all-secret-paths item
  #           else
  #             [ ];

  #         deduplicate-secret-paths =
  #           secret-paths:
  #           builtins.attrNames (
  #             builtins.listToAttrs (
  #               builtins.map (path: {
  #                 name = path;
  #                 value = null;
  #               }) secret-paths
  #             )
  #           );

  #         enumerate-secret-paths =
  #           secret-paths:
  #           builtins.listToAttrs (
  #             lib.imap0 (index: path: {
  #               name = path;
  #               value = index;
  #             }) secret-paths
  #           );

  #         recursively-erase-paths =
  #           secret-paths:
  #           let
  #             secret-indices = enumerate-secret-paths secret-paths;
  #             recurse =
  #               item:
  #               if lib.isType "knot-secret" item then
  #                 { "@replaced-with-secret-at-index" = secret-indices.${item.file}; }
  #               else if lib.isDerivation item then
  #                 item
  #               else if builtins.isAttrs item then
  #                 builtins.mapAttrs (_: recurse) item
  #               else if builtins.isList item then
  #                 builtins.map recurse item
  #               else
  #                 item;
  #           in
  #           recurse;
  #       in
  #       toplevel: rec {
  #         secrets = lib.pipe toplevel [
  #           recursively-get-all-secret-paths
  #           deduplicate-secret-paths
  #         ];

  #         payload = recursively-erase-paths secrets toplevel;
  #       };

  #     prepare-systemd =
  #       { pkgs, settings }:
  #       let
  #         inherit (scrub settings) secrets payload;

  #         template = pkgs.writers.writeJSON "knot.json" payload;

  #         secrets' = lib.imap0 (i: path: rec {
  #           identifier = "secret_${toString i}";
  #           jq-varname = "$" + identifier;
  #           source-path = path;
  #           runtime-credential-path = "$CREDENTIALS_DIRECTORY/${identifier}";
  #         }) secrets;

  #         jq-secrets-args = builtins.concatMap (secret: [
  #           "--rawfile"
  #           secret.identifier
  #           secret.runtime-credential-path
  #         ]) secrets';

  #         jq-secrets-expr = "[ ${
  #           builtins.concatStringsSep ", " (builtins.map (secret: secret.jq-varname) secrets')
  #         } ]";

  #         jq-script = pkgs.writeText "substitute-knot-secrets.jq" ''
  #           ${jq-secrets-expr} as $secrets | walk(
  #             if type == "object" and keys == [ "@replaced-with-secret-at-index" ]
  #             then
  #               $secrets[.["@replaced-with-secret-at-index"]]
  #             end
  #           )
  #         '';

  #         jq-incantation = pkgs.writeShellScript "substitute-knot-secrets" ''
  #           ${lib.getExe' pkgs.coreutils "cat"} ${template} | ${lib.getExe pkgs.jq} ${
  #             builtins.concatStringsSep " " (
  #               [
  #                 "-f"
  #                 "${jq-script}"
  #               ]
  #               ++ jq-secrets-args
  #             )
  #           }
  #         '';
  #       in
  #       {
  #         config-template = template;
  #         substitute-config = jq-incantation;
  #         credentials = builtins.map (secret: {
  #           identifier = secret.identifier;
  #           path = secret.source-path;
  #         }) secrets';
  #       };
  #   in
  #   {
  #     scrub = lib.mkOption {
  #       type = lib.types.raw;
  #       readOnly = true;
  #       default = scrub;
  #     };

  #     prepare-systemd = lib.mkOption {
  #       type = lib.types.raw;
  #       readOnly = true;
  #       default = prepare-systemd;
  #     };
  #   };
}
