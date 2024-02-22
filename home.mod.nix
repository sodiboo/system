{home-manager, ...}: {
  shared.modules = [
    home-manager.nixosModules.home-manager
    ({config, ...}: {
      users.users.sodiboo = {
        isNormalUser = true;
        description = "sodiboo";
        extraGroups = ["wheel"];
      };

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.sodiboo = {
        home.username = "sodiboo";
        home.homeDirectory = "/home/sodiboo";

        home.stateVersion = "22.11";
        imports = config._module.args.home_modules;
      };
    })
  ];
}
