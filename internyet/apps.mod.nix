{nixpkgs-stable, ...}:
{
  nitrogen.nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "dotnet-runtime-6.0.36"
  ];
  nitrogen.home-shortcut = {pkgs, ...}:
    let
      pkgs-stable = import nixpkgs-stable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      in
   {
    home.packages = [
      pkgs-stable.warsow
      pkgs.mindustry-wayland
      pkgs.xonotic
      pkgs.openra # borked
      pkgs.veloren
      pkgs.hedgewars
      pkgs-stable.zeroad
      pkgs.ddnet
      pkgs.warzone2100
      pkgs-stable.openspades
      pkgs.unciv
      pkgs-stable.superTuxKart
      pkgs.openttd
      pkgs-stable.lmms
      pkgs-stable.milkytracker
      pkgs.blender
      pkgs.godot
      pkgs.krita
      pkgs.zap
      pkgs.python3
      pkgs.mumble
      pkgs-stable.linphone
      pkgs-stable.eiskaltdcpp
      # already have obs studio
      # caddy dealt with next door
      # already have an irc client: Thunderbird
    ];
  };
}