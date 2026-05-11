{ lib, config, ... }:
{
  options.keys = lib.mkOption {
    default = { };
    type = lib.types.attrsWith {
      placeholder = "fully qualified domain name";
      elemType = lib.types.submodule (
        { name, ... }:
        {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = name;
            };

            algorithm = lib.mkOption {
              type = lib.types.enum [
                "hmac-md5"
                "hmac-sha1"
                "hmac-sha224"
                "hmac-sha256"
                "hmac-sha384"
                "hmac-sha512"
              ];
            };

            secretFile = lib.mkOption { type = lib.types.pathWith { inStore = false; }; };
          };
        }
      );
    };
  };

  config._module.render =
    knotc:
    lib.mkMerge (
      builtins.map (key: {
        main-phase = config.lib.config-directives-for-section {
          inherit knotc;
          section = "key[${key.id}]";
          options = {
            algorithm = "hmac-sha256";
            secret = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==";
            comment = "this is a stub value, which is overwritten during service startup";
          };
        };
      }) (builtins.attrValues config.keys)
    );
}
