{
  universal.home-shortcut =
    { pkgs, ... }:
    {
      programs.git.enable = true;
      programs.git.settings.user.name = "sodiboo";
      programs.git.settings.user.email = "git@sodi.boo";
      programs.gh.enable = true;
      programs.gh.gitCredentialHelper.enable = true;

      programs.lazygit.enable = true;

      programs.git.ignores = [ "**/.vscode" ];
    };
}
