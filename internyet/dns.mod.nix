{
  nitrogen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.internyet.dns.slugs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      config = {
        systemd.timers."update-internyet-dns" = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5s";
            OnUnitInactiveSec = "60s";
            Unit = "update-internyet-dns.service";
          };
        };

        systemd.services."update-internyet-dns" = {
          serviceConfig = {
            Type = "oneshot";
            LoadCredential = [ "internyet-client-key:${config.sops.secrets."internyet-client-key".path}" ];
          };

          script = builtins.concatStringsSep "\n" (
            config.internyet.dns.slugs |> map
              (subdomain: ''
                ${lib.getExe pkgs.curl} --cert ${./client.crt} --key $CREDENTIALS_DIRECTORY/internyet-client-key --request POST -H 'X-SillyCSRF: false' https://v6.dns.c.nyet/api/v2/AAAA/${subdomain}/this
                ${lib.getExe pkgs.curl} --cert ${./client.crt} --key $CREDENTIALS_DIRECTORY/internyet-client-key --request POST -H 'X-SillyCSRF: false' https://v4.dns.c.nyet/api/v2/A/${subdomain}/this
              '')
          );
        };

        sops.secrets."internyet-client-key".sopsFile = ./secrets.yaml;
      };
    };
}
