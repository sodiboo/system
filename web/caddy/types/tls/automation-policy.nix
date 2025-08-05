{ lib, config, ... }:
{
  options.caddy.lib.types.tls.automation-policy = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.tls.automation-policy = config.caddy.lib.types.sparse-submodule {
    options = {
      subjects = lib.mkOption { type = lib.types.listOf lib.types.str; };
      issuers = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.tls.issuer; };
      renewal_window_ratio = lib.mkOption { type = lib.types.float; };
      key_type = lib.mkOption {
        type = lib.types.enum [
          "ed25519"
          "p256"
          "p384"
          "rsa2048"
          "rsa4096"
        ];
      };
      storage = lib.mkOption { type = config.caddy.lib.types.storage; };
      on_demand = lib.mkOption { type = lib.types.bool; };
    };
  };
}
