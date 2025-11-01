{
  universal =
    {
      pkgs,
      lib,
      ...
    }:
    {
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
        socat
        jq
        just
        file
        bc
        dust
        moreutils
        sodi-revshell
      ];

      home-shortcut =
        { lib, ... }:
        {
          nixpkgs.overlays = lib.mkForce null;
        };
    };
}
