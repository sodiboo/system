{sops-nix, ...}: {
  universal.modules = [
    sops-nix.nixosModules.sops
    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.defaultSopsFormat = "yaml";

      # sync ~/.ssh/sops out-of-band
      # ssh-to-age -private-key -i ~/.ssh/sops > ~/.config/sops/age/keys.txt
      sops.age.keyFile = "/home/sodiboo/.config/sops/age/keys.txt";
    }
  ];

  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        sops
      ];
    })
  ];
}
