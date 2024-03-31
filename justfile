niri-cfg:
    nix eval --quiet --quiet --override-input niri /home/sodiboo/niri-flake --raw .#nixosConfigurations.$(hostname).config.home-manager.users.sodiboo.programs.niri.finalConfig
niri-rebuild:
    nixos-rebuild --quiet --quiet --override-input niri /home/sodiboo/niri-flake build