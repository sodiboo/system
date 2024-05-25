{
  universal.modules = [
    ({pkgs, ...}: {
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
      programs.git.ignores = ["**/.envrc" "**/.direnv"];
    })
  ];
}
