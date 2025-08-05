{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.vars = lib.types.attrsOf (lib.types.listOf lib.types.str);
}
