{
  description = "sodi flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence/home-manager-v2";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.inputs.home-manager.follows = "home-manager";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    flashrom-meson.url = "github:roger/flashrom-meson-nix";
    flashrom-meson.flake = false;

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";

    nari.url = "github:sodiboo/nixos-razer-nari";

    niri.url = "github:sodiboo/niri-flake";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    lan-mouse.url = "github:feschber/lan-mouse";
    lan-mouse.inputs.nixpkgs.follows = "nixpkgs";

    sodipkgs-simutrans.url = "github:sodiboo/nixpkgs/simutrans";

    picocss.url = "github:picocss/pico";
    picocss.flake = false;

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    nil.url = "github:oxalica/nil";
    nil.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    swww.url = "github:LGFae/swww";
    swww.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    raw-inputs:
    let
      inputs = builtins.mapAttrs (
        input-name: raw-input:
        builtins.foldl'
          (
            input: module-class:
            if input ? ${module-class} then
              input
              // {
                ${module-class} = builtins.mapAttrs (
                  module-name:
                  raw-inputs.nixpkgs.lib.setDefaultModuleLocation "${input-name}.${module-class}.${module-name}"
                ) input.${module-class};
              }
            else
              input
          )
          raw-input
          [
            "nixosModules"
            "homeModules"
          ]
      ) raw-inputs;
    in
    let
      inherit (inputs) self nixpkgs;

      inherit (nixpkgs.lib.attrsets) filterAttrs mapAttrs zipAttrs;
      inherit (nixpkgs.lib.strings) hasSuffix;
      inherit (nixpkgs.lib.lists) filter map;

      inherit (nixpkgs.lib.trivial) const toFunction;
      inherit (nixpkgs.lib.filesystem) listFilesRecursive;
      inherit (nixpkgs.lib.modules) setDefaultModuleLocation;

      params = inputs // {
        profiles = raw-configs;
        systems = mapAttrs (const (system: system.config)) configs;
      };

      # It is important to note, that when adding a new `.mod.nix` file, you need to run `git add` on the file.
      # If you don't, the file will not be included in the flake, and the modules defined within will not be loaded.
      all-modules =
        map (
          path:
          mapAttrs (profile: setDefaultModuleLocation "${path}#${profile}") (toFunction (import path) params)
        ) (filter (hasSuffix ".mod.nix") (listFilesRecursive "${self}"))
        ++ [
          {
            universal.options.id = nixpkgs.lib.mkOption {
              type = nixpkgs.lib.types.int;
            };
          }
          elements
        ];

      elements = {
        # used as an identifier for ip addresses, etc.
        # and this set defines what systems are exported
        carbon.id = 6;
        nitrogen.id = 7;
        oxygen.id = 8;
        sodium.id = 11;
        iridium.id = 77;
      };

      raw-configs = mapAttrs (const (
        modules:
        nixpkgs.lib.nixosSystem {
          inherit modules;
        }
        // {
          inherit modules; # expose this next to e.g. `config`, `option`, etc.
        }
      )) (zipAttrs all-modules);

      configs = filterAttrs (name: config: elements ? ${name}) raw-configs;

      vms =
        mapAttrs
          (
            hostname:
            {
              config,
              pkgs,
              ...
            }:
            (
              let
                ssh = pkgs.writeScript "vm-ssh" ''
                  # do not verify the host key, do not store the host key, do not show a warning about the host key
                  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
                      -o User=sodiboo localhost -p $SSH_VM_PORT "$@"
                '';

                exit = pkgs.writeScript "vm-exit" ''
                  ${ssh} /run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl poweroff
                '';
              in
              pkgs.writeShellScript "${hostname}-vm" ''
                export SSH_VM_PORT=''${SSH_VM_PORT:-60022}

                THIS_PID=$$

                VM_TEMP_DIR=$(mktemp -d /tmp/${hostname}-XXXXXX)
                cd $VM_TEMP_DIR

                echo
                echo
                echo 'Starting VM...'
                echo

                QEMU_NET_OPTS="hostfwd=tcp::$SSH_VM_PORT-:22" ${config.virtualisation.vmVariant.system.build.vm}/bin/run-${hostname}-vm &
                QEMU_PID=$!

                monitor() {
                  tail --pid=$QEMU_PID -f /dev/null
                  kill $THIS_PID
                }
                cleanup() {
                  echo
                  echo
                  echo "The VM has exited. You can now have your normal shell back."
                  echo
                  rm -rf $VM_TEMP_DIR
                  exit
                }
                trap cleanup EXIT

                monitor &
                MONITOR_PID=$!

                export ssh="${ssh}"
                export exit="${exit}"

                sleep 1

                while kill -0 $MONITOR_PID 2>/dev/null; do
                  echo "Use $(tput setaf 2)\$ssh$(tput sgr0) to execute commands in the VM"
                  echo "Use $(tput setaf 1)\$exit$(tput sgr0) to power off the VM"
                  echo "Press $(tput setaf 4)Ctrl+D$(tput sgr0) to see this message again"
                  $SHELL
                done
              ''
            )
          )
          {
            inherit (raw-configs) sodium nitrogen;
          };

      systems = [
        "x86_64-linux"
        "aarch64-linux" # i don't have such a machine, but might as well make the devtooling in this flake work out of the box.
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # for use in nix repl
      p = s: builtins.trace "\n\n${s}\n" "---";

      devShells = forAllSystems (
        system:
        import ./shell.nix {
          inherit system;
          flake = self;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      nixosConfigurations = configs;

      # This is NOT intended for primary consumption.
      # It's just a shorthand so i can more easily access it when testing.
      # If you want to consume my Sharkey package, directly import `./sharkey/{package,module}.nix`.
      packages.x86_64-linux.sharkey = self.nixosConfigurations.oxygen.pkgs.sharkey;

      apps.x86_64-linux = mapAttrs (name: script: {
        type = "app";
        program = "${script}";
      }) vms;

      # This is useful to rebuild all systems at once, for substitution
      all-systems = nixpkgs.legacyPackages.x86_64-linux.runCommand "all-systems" { } (
        ''
          mkdir $out
        ''
        + (builtins.concatStringsSep "\n" (
          nixpkgs.lib.attrsets.mapAttrsToList (name: config: ''
            ln -s ${config.config.system.build.toplevel} $out/${name}
          '') self.nixosConfigurations
        ))
      );
    };
}
