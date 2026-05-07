{ nixocaine, ... }:
{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      imports = [ nixocaine.nixosModules.default ];

      systemd.sockets.iocaine = {
        description = "iocaine main listening socket";

        wantedBy = [ "sockets.target" ];
        before = [ "sockets.target" ];

        socketConfig = {
          ListenStream = "@iocaine";
          Accept = false;
          FileDescriptorName = "main";
        };
      };

      systemd.services.iocaine = {
        requires = [ "iocaine.socket" ];

        serviceConfig = {
          RestrictAddressFamilies = lib.mkForce [ "AF_UNIX" ];
          IPAddressDeny = [ "any" ];
          PrivateNetwork = true;
        };
      };

      services.iocaine = {
        enable = true;

        config = {
          initial-seed-file = "/run/current-system/boot.json";
          server.main = {
            bind = "sd-listen:main";
            mode = "http";
            use.handler-from = "default";
          };

          handler.default.config = {
            ai-robots-txt-path =
              let
                ai-robots-txt-version = "1.45";
                ai-robots-txt = builtins.fetchTarball {
                  url = "https://github.com/ai-robots-txt/ai.robots.txt/archive/refs/tags/v${ai-robots-txt-version}.tar.gz";
                  sha256 = "sha256-HwRsZKQlK0t88Sz7VDQ5qZoufPTfYofZhBQ6EY3jVkg=";
                };
              in
              "${ai-robots-txt}/robots.json";

            sources = {
              wordlists = [ "${pkgs.miscfiles}/share/web2" ];
              training-corpus = builtins.map (p: "${pkgs.callPackage p { }}") (
                lib.filesystem.listFilesRecursive ./iocaine-corpus
              );
            };
          };
        };
      };
    };
}
