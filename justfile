set shell := ["fish", "-c"]
export NIX_CONFIG := "warn-dirty = false"

niri-cfg hostname=`hostname`:
    nix eval --quiet --quiet --override-input niri /home/sodiboo/niri-flake --raw .#nixosConfigurations.{{hostname}}.config.home-manager.users.sodiboo.programs.niri.finalConfig
niri-rebuild:
    nixos-rebuild --quiet --quiet --override-input niri /home/sodiboo/niri-flake build

build hostname=`hostname`:
  nom build .#nixosConfigurations.{{hostname}}.config.system.build.toplevel

fmt:
    nix fmt -- --quiet *
prep: fmt
    nix flake update
    git add .