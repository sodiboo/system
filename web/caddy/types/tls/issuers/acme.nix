{ lib, config, ... }:
let
  nonzero-port = lib.types.addCheck lib.types.port (x: x != 0);
in
{
  caddy.lib.types.tls.issuer.acme = config.caddy.lib.types.sparse-submodule {
    options = {
      module = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "acme" ]; };

      ca = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      test_ca = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      email = config.caddy.lib.mkRequiredOption { type = config.caddy.lib.types.nonempty-str; };
      account_key = lib.mkOption { type = config.caddy.lib.types.secret; };

      external_account = lib.mkOption {
        type = lib.types.submodule {
          options = {
            key_id = lib.mkOption { type = lib.types.str; };
            mac_key = lib.mkOption { type = lib.types.str; };
          };
        };
      };

      acme_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      challenges = {
        http = {
          disabled = lib.mkOption { type = lib.types.bool; };
          alternate_port = lib.mkOption { type = nonzero-port; };
        };
        tls-alpn = {
          disabled = lib.mkOption { type = lib.types.bool; };
          alternate_port = lib.mkOption { type = nonzero-port; };
        };

        dns = config.caddy.lib.mkSparseOption {
          provider = config.caddy.lib.mkRequiredOption { type = config.caddy.lib.types.dns.provider; };

          ttl = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
          propagation_delay = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
          propagation_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

          resolvers = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };

          override_domain = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
        };

        bind_host = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      };

      trusted_roots_pem_files = lib.mkOption { type = lib.types.listOf lib.types.str; };

      preferred_chains = {
        smallest = lib.mkOption { type = lib.types.bool; };
        root_common_name = lib.mkOption { type = lib.types.listOf lib.types.str; };
        any_common_name = lib.mkOption { type = lib.types.listOf lib.types.str; };
      };

      certificate_lifetime = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
    };
  };
}
