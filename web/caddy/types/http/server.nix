{ lib, config, ... }:
{
  options.caddy.lib.types.http.server = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.http.server = config.caddy.lib.types.sparse-submodule {
    options = {
      listen = lib.mkOption { type = lib.types.listOf lib.types.str; };

      listener_wrappers = lib.mkOption {
        type = lib.types.listOf config.caddy.lib.types.listener-wrapper;
      };

      protocols = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
      listen_protocols = lib.mkOption {
        type = lib.types.listOf (lib.types.nonEmptyListOf lib.types.str);
      };

      read_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      read_header_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      write_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      idle_timeout = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      keepalive_interval = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      max_header_bytes = lib.mkOption { type = lib.types.ints.positive; };

      routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
      errors.routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
      named_routes = lib.mkOption { type = lib.types.attrsOf config.caddy.lib.types.http.route; };

      tls_connection_policies = lib.mkOption {
        type = lib.types.listOf config.caddy.lib.types.tls.connection-policy;
      };

      automatic_https = {
        disable = lib.mkOption { type = lib.types.bool; };
        disable_redirects = lib.mkOption { type = lib.types.bool; };
        disable_certificates = lib.mkOption { type = lib.types.bool; };

        skip = lib.mkOption { type = lib.types.listOf lib.types.str; };
        skip_certificates = lib.mkOption { type = lib.types.listOf lib.types.str; };

        ignore_loaded_certificates = lib.mkOption { type = lib.types.bool; };
        # prefer_wildcard = lib.mkOption { type = lib.types.bool; };
      };

      strict_sni_host = lib.mkOption { type = lib.types.bool; };
      trusted_proxies = lib.mkOption { type = config.caddy.lib.types.http.ip-source; };
      # why is that not a bool???
      trusted_proxies_strict = lib.mkOption { type = lib.types.ints.unsigned; };

      logs = config.caddy.lib.mkSparseOption {
        default_logger_name = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
        logger_names = lib.mkOption { type = lib.types.attrsOf (lib.types.listOf lib.types.str); };
        skip_hosts = lib.mkOption { type = lib.types.listOf lib.types.str; };
        skip_unmapped_hosts = lib.mkOption { type = lib.types.bool; };
        should_log_credentials = lib.mkOption { type = lib.types.bool; };
        trace = lib.mkOption { type = lib.types.bool; };
      };
    };
  };
}
