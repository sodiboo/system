{
  nitrogen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      content = pkgs.runCommandNoCC "personal-website-content" { } ''
        cp -r ${./personal-website} $out
      '';
    in
    {
      internyet.dns.slugs = [
        "=" # personal apex
        "sodiboo/cyberpink"
      ];
      caddy.sites."sodiboo.cyberpink.g.nyet".routes = [
        {
          terminal = true;
          handle = [

        {
          handler = "static_response";
          status_code = "308"; # permanent redirect

          headers.Location = [ "https://sodiboo.p.nyet{http.request.orig_uri}" ];
        }
          ];
        }
      ];
      caddy.sites."sodiboo.p.nyet".routes = [
        {
          match = [
            {
              file = {
                root = "${content}";
                try_files = [
                  "{http.request.uri.path}.html"
                  "{http.request.uri.path}/"
                  "{http.request.uri.path}"
                ];
              };
            }
          ];
          handle = [
            {
              handler = "rewrite";
              uri = "{http.matchers.file.relative}";
            }
          ];
        }
        {
          terminal = true;
          handle = config.caddy.lib.handle-static-files {
            extraFormats = [ "atom" ];
            inherit content;
          };
        }
      ];
    };
}
