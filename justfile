set shell := ["fish", "-c"]
export NIX_CONFIG := "warn-dirty = false"
export NH_OS_FLAKE := "."

niri-cfg hostname=`hostname`:
    nix eval --quiet --quiet --override-input niri /home/sodiboo/niri-flake --raw .#nixosConfigurations.{{hostname}}.config.home-manager.users.sodiboo.programs.niri.finalConfig
niri-cfg-validate hostname=`hostname`:
    just niri-cfg {{hostname}} > config.kdl
    cat config.kdl; echo
    nix run --quiet --quiet --override-input niri /home/sodiboo/niri-flake .#nixosConfigurations.{{hostname}}.config.programs.niri.package -- validate --config config.kdl
niri-cfg-watch hostname=`hostname`:
    begin fd .nix ~/niri-flake; fd .nix .; end | entr -cr just niri-cfg-validate {{hostname}}

niri-cfg-reload:
    just niri-cfg > config.kdl
    cat config.kdl | rg gestures -A 15 || true
    env /proc/$(echo $NIRI_SOCKET | rg '\.(\d+)\.sock$' -or '$1')/exe validate --config config.kdl
    cp config.kdl active-config.kdl
    ln -sf $PWD/active-config.kdl ~/.config/niri/config.kdl
niri-cfg-hot-reload:
    begin fd .nix ~/niri-flake; fd '(^justfile|\.(nix|glsl))$' .; end | entr -cr just niri-cfg-reload

niri-rebuild:
    nixos-rebuild --quiet --quiet --override-input niri /home/sodiboo/niri-flake build

build hostname=`hostname`:
  nom build .#nixosConfigurations.{{hostname}}.config.system.build.toplevel

fmt:
    nix fmt -- --quiet **.nix
prep: fmt
    nix flake update
    git add .

sys *ARGS: prep
    nh os {{ARGS}}