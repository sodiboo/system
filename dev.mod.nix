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
      ];
    })
  ];

  shared.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        rustup
        clang
        git
        gh
      ];
      programs.lazygit.enable = true;
    })
  ];
}
