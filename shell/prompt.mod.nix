{
  universal = {
    home-shortcut = {
      programs.powerline-go = {
        enable = true;
        settings.hostname-only-if-ssh = true;
        modules = [
          "host"
          "cwd"
          "perms"
          "git"
          "hg"
          "nix-shell"
          "jobs"
          # "duration" # not working
          "exit"
          "root"
        ];
      };
    };
  };
}
