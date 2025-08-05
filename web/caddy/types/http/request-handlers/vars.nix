{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.vars = lib.types.submodule {
    options.handler = lib.mkOption { type = lib.types.enum [ "vars" ]; };
    freeformType = lib.types.attrsOf lib.types.str;
  };
}
