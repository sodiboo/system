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

      nixpkgs.overlays = [
        (final: prev: {
          ai-robots-txt =
            let

              version = "1.45";
            in
            final.fetchFromGitHub {
              name = "ai.robots.txt-${version}";
              owner = "ai-robots-txt";
              repo = "ai.robots.txt";
              tag = "v${version}";
              hash = "sha256-HwRsZKQlK0t88Sz7VDQ5qZoufPTfYofZhBQ6EY3jVkg=";
            };
        })
      ];

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
            ai-robots-txt-path = "${pkgs.ai-robots-txt}/robots.json";

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
