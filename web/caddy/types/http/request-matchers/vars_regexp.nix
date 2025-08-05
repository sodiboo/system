{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.vars_regexp = lib.types.attrsOf config.caddy.lib.types.regexp;
}
