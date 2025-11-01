{
  universal.home-shortcut =
    { pkgs, ... }:
    {
      programs.git.enable = true;
      programs.git.userName = "sodiboo";
      programs.git.userEmail = "git@sodi.boo";
      programs.gh.enable = true;
      programs.gh.gitCredentialHelper.enable = true;

      programs.lazygit.enable = true;

      programs.git.ignores = [ "**/.vscode" ];
    };
}
