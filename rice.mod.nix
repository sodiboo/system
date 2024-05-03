{
  shared.modules = [
    {
      boot.plymouth.enable = true;
    }
  ];
  shared.home_modules = [
    {
      programs.btop.enable = true;
      programs.btop.settings.theme_background = false;
    }
  ];
}
