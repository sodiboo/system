set shell := ["fish", "-c"]
export NIX_CONFIG := "warn-dirty = false"

niri-cfg:
    nix eval --quiet --quiet --override-input niri /home/sodiboo/niri-flake --raw .#nixosConfigurations.$(hostname).config.home-manager.users.sodiboo.programs.niri.finalConfig
niri-rebuild:
    nixos-rebuild --quiet --quiet --override-input niri /home/sodiboo/niri-flake build

build hostname=`hostname`:
  nom build .#nixosConfigurations.{{hostname}}.config.system.build.toplevel

fmt:
    nix fmt -- --quiet *
prep: fmt
    nix flake update
    git add .

build-vm hostname=`hostname`: prep
    nom build .#nixosConfigurations.{{hostname}}.config.virtualisation.vmVariant.system.build.vm
run-vm hostname=`hostname`:
    just build-vm {{hostname}}
    ./result/bin/run-{{hostname}}-vm &
    set QEMU_PID $last_pid
    # '\n\n\n---\n\nUse ./ssh-vm to execute commands on the VM'
    , remote-viewer spice://127.0.0.1:5930 &
    fish
    ./ssh-vm /run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl poweroff
clean-vm hostname=`hostname`:
    -rm {{hostname}}.qcow2
    just run-vm {{hostname}}
ssh-vm:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR localhost -p 2222
