{ lib, config, ... }:
{
  options.zones = lib.mkOption {
    default = { };
    type = lib.types.attrsWith {
      placeholder = "fully qualified domain name";
      elemType = lib.types.submodule (
        { name, ... }:
        {
          imports = [ ./zone-items.nix ];

          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = name;
            };

            template = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            records = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
            };
          };

          freeformType = config.lib.types.config-section;
        }
      );
    };
  };

  config.assertions = builtins.concatMap (
    zone:
    let
      template = if zone.template != null then config.templates.${zone.template} else { };

      defaults = {
        catalog-role = "none";
      };

      cfg =
        lib.genAttrs
          [
            "catalog-role"
            "catalog-template"
            "catalog-zone"
            "catalog-group"
          ]
          (
            attr:
            let
              cfg-zone = zone.${attr};
              cfg-template = template.${attr} or null;
              cfg-default = defaults.${attr} or null;
            in
            if cfg-zone != null then
              cfg-zone
            else if cfg-template != null then
              cfg-template
            else
              cfg-default
          );
    in
    map
      (
        { assertion, message }:
        {
          inherit assertion;
          message = "knot(zone `${zone.domain}`): ${message}";
        }
      )
      [
        {
          assertion = zone.template != null -> config.templates ? ${zone.template};
          message = ''`template == "${zone.template}"` but no such template is defined.'';
        }
        {
          assertion = cfg.catalog-role == "member" -> cfg.catalog-zone != null;
          message = ''`catalog-role == "member"`, and therefore this zone requires a `catalog-zone`, but none is assigned.'';
        }
        {
          assertion = cfg.catalog-role != "member" -> cfg.catalog-zone == null;
          message = ''`catalog-role == "${cfg.catalog-role}"`, but this zone is assigned to `catalog-zone == "${cfg.catalog-zone}"` which is only allowed for `catalog-role == "member"`.'';
        }
        {
          assertion = cfg.catalog-role != "member" -> cfg.catalog-group == null;
          message = ''`catalog-role == "${cfg.catalog-role}"`, but this zone is assigned to `catalog-group == "${cfg.catalog-group}"` which is only allowed for `catalog-role == "member"`.'';
        }
        {
          assertion = cfg.catalog-role == "interpret" -> cfg.catalog-template != null;
          message = ''`catalog-role == "interpret"`, and therefore this zone requires a `catalog-template`, but none is defined.'';
        }
        {
          assertion = cfg.catalog-role != "interpret" -> cfg.catalog-template == null;
          message = ''`catalog-role == "${cfg.catalog-role}"`, but this zone has a `catalog-template` defined, which is only allowed for `catalog-role == "interpret"`.'';
        }
      ]
  ) (builtins.attrValues config.zones);

  config._module.render =
    knotc:
    lib.mkMerge (
      builtins.map (
        zone:
        let
          template = if zone.template != null then config.templates.${zone.template} else { };

          defaults = { };

          cfg =
            lib.genAttrs
              [
                "zonefile-load"
                "catalog-role"
              ]
              (
                attr:
                let
                  cfg-zone = zone.${attr};
                  cfg-template = template.${attr} or null;
                  cfg-default = defaults.${attr} or null;
                in
                if cfg-zone != null then
                  cfg-zone
                else if cfg-template != null then
                  cfg-template
                else
                  cfg-default
              )
            // {
              records = template.records or [ ] ++ zone.records;
            };
        in
        {
          main-phase = lib.mkMerge [
            (config.lib.config-directives-for-section {
              inherit knotc;
              section = "zone[${zone.domain}]";
              options = builtins.removeAttrs zone [
                "domain"
                "records"
                "storage"
                "notify"
                "master"
                "ddns-master"
              ];
            })
            (lib.mkIf (cfg.catalog-role == "generate") [
              "${
                knotc [
                  "conf-set"
                  "zone[${zone.domain}].storage"
                ]
              } $zones/catalog" # drv output
            ])
            (lib.mkIf (cfg.catalog-role == "interpret") [
              (knotc [
                "conf-set"
                "zone[${zone.domain}].file"
                "${builtins.toFile "dummy.zone" ''
                  @ 0 IN SOA  invalid. invalid. ( 0 0 0 0 0 )
                  @ 0 IN NS   invalid.
                  version 0 IN TXT "2"
                ''}"
              ])

            ])
            (lib.mkIf (cfg.catalog-role != "generate" && cfg.catalog-role != "interpret") [
              "${
                knotc [
                  "conf-set"
                  "zone[${zone.domain}].storage"
                ]
              } $zones" # drv output
              "cp ${builtins.toFile "dummy.zone" ''
                @ 0 IN SOA  invalid. invalid. ( 0 0 0 0 0 )
                @ 0 IN NS   invalid.
              ''} $zones/${zone.domain}.zone"
            ])
          ];

          notify-phase = config.lib.config-directives-for-options {
            inherit knotc;
            section = "zone[${zone.domain}]";
            options = {
              inherit (zone) notify master ddns-master;
            };
          };

          zone-phases.${zone.domain} =
            lib.mkIf (cfg.catalog-role != "generate" && cfg.catalog-role != "interpret")
              (
                lib.mkMerge [
                  (knotc [
                    "zone-unset"
                    zone.domain
                    "@"
                  ])
                  (lib.mkMerge (
                    map (
                      record:
                      knotc (
                        [
                          "zone-set"
                          zone.domain
                        ]
                        ++ record
                      )
                    ) cfg.records
                  ))
                ]
              );
        }
      ) (builtins.attrValues config.zones)
    );
}
