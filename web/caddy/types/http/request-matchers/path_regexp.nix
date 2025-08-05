{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.path_regexp = config.caddy.lib.types.regexp;
}
