{
  universal.modules = [
    ({
      pkgs,
      lib,
      ...
    }: {
      nixpkgs.overlays = [
        (final: prev: {
          # Getting a shell to run in annoying, non-tty nested environments
          # e.g. for debugging stuff inside of xwayland-run without using xterm
          # or in the environment of `niri msg action spawn` without needing to spawn a graphical window
          sodi-revshell = final.symlinkJoin {
            name = "revshell";
            paths = [
              (final.writeScriptBin "revsh-attach" ''
                ${lib.getExe final.socat} file:$(tty),raw,echo=0 tcp:127.0.0.1:"$1"
              '')
              (final.writeScriptBin "revsh-here" ''
                ${lib.getExe final.socat} exec:"sh -lic $SHELL",pty,stderr,setsid,sigint,sane tcp-listen:"$1"
              '')
            ];
          };
        })
      ];
      environment.systemPackages = with pkgs; [
        chase
        tldr
        eza
        bat
        fd
        ripgrep
        bottom
        entr
        difftastic
        kakoune
        socat
        jq
        just
        file
        bc
        dust
        moreutils
        sodi-revshell
      ];
    })
    {
      # This domain has improperly configured IPv6 for now
      # And that causes svn to hang for at least 4 minutes
      networking.extraHosts = ''
        176.31.12.55 servers.simutrans.org
      '';
    }
  ];

  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        rustup
        clang
        bun
      ];

      programs.git.enable = true;
      programs.git.userName = "sodiboo";
      programs.git.userEmail = "git@sodi.boo";
      programs.gh.enable = true;
      programs.gh.gitCredentialHelper.enable = true;

      programs.lazygit.enable = true;

      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;
      programs.git.ignores = [];
    })
  ];
}
