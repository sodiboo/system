{ lib, config, ... }:
{
  options.caddy.lib.types.secret = lib.mkOption {
    type = lib.types.optionType;
    readOnly = true;
    default = lib.mkOptionType {
      name = "caddy-secret";
      description = "caddy secret";
      descriptionClass = "noun";

      check = lib.isType "caddy-secret";
      merge =
        (lib.types.submodule {
          options = {
            _type = lib.mkOption { type = lib.types.enum [ "caddy-secret" ]; };
            file = lib.mkOption {
              type = lib.types.addCheck (lib.types.pathWith { inStore = false; }) (
                path: !(builtins.hasContext path)
              );
            };
          };
        }).merge;
    };
  };

  options.caddy.lib.mkSecret = lib.mkOption {
    type = lib.types.functionTo config.caddy.lib.types.secret;
    readOnly = true;
    default = lib.setType "caddy-secret";
  };

  options.caddy.lib.secrets-impl =
    let
      scrub =
        let
          recursively-get-all-secret-paths =
            item:
            if lib.isType "caddy-secret" item then
              [ item.file ]
            else if lib.isDerivation item then
              [ ]
            else if builtins.isAttrs item then
              builtins.concatMap recursively-get-all-secret-paths (builtins.attrValues item)
            else if builtins.isList item then
              builtins.concatMap recursively-get-all-secret-paths item
            else
              [ ];

          deduplicate-secret-paths =
            secret-paths:
            builtins.attrNames (
              builtins.listToAttrs (
                builtins.map (path: {
                  name = path;
                  value = null;
                }) secret-paths
              )
            );

          enumerate-secret-paths =
            secret-paths:
            builtins.listToAttrs (
              lib.imap0 (index: path: {
                name = path;
                value = index;
              }) secret-paths
            );

          recursively-erase-paths =
            secret-paths:
            let
              secret-indices = enumerate-secret-paths secret-paths;
              recurse =
                item:
                if lib.isType "caddy-secret" item then
                  { "@replaced-with-secret-at-index" = secret-indices.${item.file}; }
                else if lib.isDerivation item then
                  item
                else if builtins.isAttrs item then
                  builtins.mapAttrs (_: recurse) item
                else if builtins.isList item then
                  builtins.map recurse item
                else
                  item;
            in
            recurse;
        in
        toplevel: rec {
          secrets = lib.pipe toplevel [
            recursively-get-all-secret-paths
            deduplicate-secret-paths
          ];

          payload = recursively-erase-paths secrets toplevel;
        };

      prepare-systemd =
        { pkgs, settings }:
        let
          inherit (scrub settings) secrets payload;

          template = pkgs.writers.writeJSON "caddy.json" payload;

          secrets' = lib.imap0 (i: path: rec {
            identifier = "secret_${toString i}";
            jq-varname = "$" + identifier;
            source-path = path;
            runtime-credential-path = "$CREDENTIALS_DIRECTORY/${identifier}";
          }) secrets;

          jq-secrets-args = builtins.concatMap (secret: [
            "--rawfile"
            secret.identifier
            secret.runtime-credential-path
          ]) secrets';

          jq-secrets-expr = "[ ${
            builtins.concatStringsSep ", " (builtins.map (secret: secret.jq-varname) secrets')
          } ]";

          jq-script = pkgs.writeText "substitute-caddy-secrets.jq" ''
            ${jq-secrets-expr} as $secrets | walk(
              if type == "object" and keys == [ "@replaced-with-secret-at-index" ]
              then
                $secrets[.["@replaced-with-secret-at-index"]]
              end
            )
          '';

          jq-incantation = pkgs.writeShellScript "substitute-caddy-secrets" ''
            ${lib.getExe' pkgs.coreutils "cat"} ${template} | ${lib.getExe pkgs.jq} ${
              builtins.concatStringsSep " " (
                [
                  "-f"
                  "${jq-script}"
                ]
                ++ jq-secrets-args
              )
            }
          '';
        in
        {
          config-template = template;
          substitute-config = jq-incantation;
          credentials = builtins.map (secret: {
            identifier = secret.identifier;
            path = secret.source-path;
          }) secrets';
        };
    in
    {
      scrub = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
        default = scrub;
      };

      prepare-systemd = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
        default = prepare-systemd;
      };
    };
}
