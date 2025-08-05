{ lib, config, ... }:
{
  options.caddy.lib.types.http.headers = lib.mkOption {
    type = lib.types.optionType;
    readOnly = true;
    default = lib.types.attrsOf (lib.types.nullOr (lib.types.listOf lib.types.str));
  };
}
