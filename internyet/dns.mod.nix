{
  nitrogen = {lib, pkgs, config, ...}: {
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
          LoadCredential = ["internyet-client-key:${config.sops.secrets."internyet-client-key".path}"];
        };

        script = builtins.concatStringsSep "\n" (map (subdomain: ''
           ${lib.getExe pkgs.curl} --cert ${./client.crt} --key $CREDENTIALS_DIRECTORY/internyet-client-key --request POST -H 'X-SillyCSRF: false' https://v6.dns.c.nyet/api/v2/AAAA/${subdomain}/this
           ${lib.getExe pkgs.curl} --cert ${./client.crt} --key $CREDENTIALS_DIRECTORY/internyet-client-key --request POST -H 'X-SillyCSRF: false' https://v4.dns.c.nyet/api/v2/A/${subdomain}/this
        '') [
          "about"
          "static"
          "social"
          "sodiboo/total-anarchy"
          "sodiboo/bazed"
        ]);
      };

        sops.secrets."internyet-client-key".sopsFile = ./secrets.yaml;
  };
}