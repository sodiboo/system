{
  oxygen =
    { lib, pkgs, ... }:
    {
      options.caddy.lib.iocaine = lib.mkOption { readOnly = true; };
      config.caddy.lib.iocaine = {
        match = [
          {
            method = [
              "GET"
              "HEAD"
            ];
          }
        ];
        handle = [
          {
            handler = "reverse_proxy";
            upstreams = [ { dial = "unix/@iocaine"; } ];
            handle_response = [
              {
                match.status_code = [ 421 ]; # Misdirected Request
              }
            ];
          }
        ];
      };
    };
}
