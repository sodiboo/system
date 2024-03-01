{
  shared.modules = [
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
        micro
        socat
        jq
        file
        bc
        btop
        dust
      ];
    })
  ];

  shared.home_modules = [
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
