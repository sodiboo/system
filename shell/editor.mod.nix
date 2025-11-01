{
  universal = {
    programs.fish.interactiveShellInit = ''
      set EDITOR kak
    '';

    home-shortcut =
      { pkgs, ... }:
      {
        programs.micro.enable = true;
        home.packages = [ pkgs.kakoune ];
      };
  };
}
