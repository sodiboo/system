{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.invoke = lib.types.submodule {
    options = {
      handler = lib.mkOption { type = lib.types.enum [ "invoke" ]; };
      name = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
    };
  };
}
