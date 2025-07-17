{ systems, ... }:
{
  oxygen =
    { lib, ... }:
    {
      options.reverse-proxy = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              extra-public-ports = lib.mkOption {
                default = [ ];
                type = lib.types.listOf lib.types.int;
              };

              locations = lib.mkOption {
                default = { };
                type = lib.types.attrsOf (
                  lib.types.attrTag {
                    socket = lib.mkOption { type = lib.types.str; };
                    url = lib.mkOption { type = lib.types.str; };
                    localhost = lib.mkOption {
                      type = lib.types.submodule {
                        options.port = lib.mkOption { type = lib.types.port; };
                      };
                    };
                    vpn = lib.mkOption {
                      type = lib.types.attrTag (
                        builtins.mapAttrs (
                          _: _:
                          lib.mkOption {
                            type = lib.types.submodule { options.port = lib.mkOption { type = lib.types.port; }; };
                          }
                        ) systems
                      );
                      apply = cfg: {
                        host = builtins.head (builtins.attrNames cfg);
                        inherit (builtins.head (builtins.attrValues cfg)) port;
                      };
                    };
                  }
                );
                apply = builtins.mapAttrs (
                  _: cfg:
                  {
                    url = cfg;
                    socket.url = "unix:${cfg.socket}";
                    localhost.url = "http://127.0.0.1:${toString cfg.localhost.port}";
                    vpn.url = "http://${systems.${cfg.vpn.host}.vpn.hostname}:${toString cfg.vpn.port}";
                  }
                  .${builtins.head (builtins.attrNames cfg)}
                );
              };
            };
          }
        );
      };
    };
}
