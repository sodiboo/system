{
  description = "sodi flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-monitored.url = "github:ners/nix-monitored";

    sops-nix.url = "github:Mic92/sops-nix";

    stylix.url = "github:danth/stylix";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    nari.url = "github:sodiboo/nixos-razer-nari";

    niri.url = "github:sodiboo/niri-flake";
    niri-working-tree.url = "github:sodiboo/niri/support-lan-mouse";
    niri-working-tree.flake = false;

    lan-mouse.url = "github:feschber/lan-mouse";

    conduwuit.url = "github:girlbossceo/conduwuit";

    sodipkgs-simutrans.url = "github:sodiboo/nixpkgs/simutrans";
    sodipkgs-stackblur-go.url = "github:sodiboo/nixpkgs/stackblur";
    sodipkgs-itch.url = "github:sodiboo/nixpkgs/itch";

    picocss.url = "github:picocss/pico";
    picocss.flake = false;

    nixpkgs-with-meilisearch-at-1-8-3.url = "github:NixOS/nixpkgs/6edd5cc7bd8eb73d2e7c2f05b34c04a7a4d02de9";

    zen-browser.url = "github:MarceColl/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs:
    with nixpkgs.lib; let
      match = flip getAttr;
      read_dir_recursively = dir:
        concatMapAttrs (this:
          match {
            directory = mapAttrs' (subpath: nameValuePair "${this}/${subpath}") (read_dir_recursively "${dir}/${this}");
            regular = {
              ${this} = "${dir}/${this}";
            };
            symlink = {};
          }) (builtins.readDir dir);

      # `const` helper function is used extensively: the function is constant in regards to the name of the attribute.

      params =
        inputs
        // {
          configs = raw_configs;
          elements = {
            nitrogen = 7;
            oxygen = 8;
            sodium = 11;
            iridium = 77;
          };
          inherit merge extras;
        };

      # It is important to note, that when adding a new `.mod.nix` file, you need to run `git add` on the file.
      # If you don't, the file will not be included in the flake, and the modules defined within will not be loaded.

      read_all_modules = flip pipe [
        read_dir_recursively
        (filterAttrs (flip (const (hasSuffix ".mod.nix"))))
        (mapAttrs (const import))
        (mapAttrs (const (flip toFunction params)))
      ];

      merge = prev: this:
        {
          modules = prev.modules or [] ++ this.modules or [];
          home_modules = prev.home_modules or [] ++ this.home_modules or [];
        }
        // (optionalAttrs (prev ? system || this ? system) {
          system = prev.system or this.system;
        });

      all_modules = attrValues (read_all_modules "${self}");

      raw_configs' = builtins.zipAttrsWith (machine:
        if machine == "extras"
        then mergeAttrsList
        else builtins.foldl' merge {})
      all_modules;

      raw_configs = builtins.removeAttrs raw_configs' ["extras"];

      extras = raw_configs'.extras or {};

      configs = builtins.mapAttrs (const (config:
        nixpkgs.lib.nixosSystem {
          inherit (config) system;
          modules =
            config.modules
            ++ [
              {
                _module.args.home_modules = config.home_modules;
              }
            ];
        }))
      raw_configs;
    in {
      # for use in nix repl
      p = s: builtins.trace "\n\n${s}\n" "---";

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      nixosConfigurations = builtins.mapAttrs (name: const configs.${name}) params.elements;

      # This is useful to rebuild all systems at once, for substitution
      all-systems = nixpkgs.legacyPackages.x86_64-linux.runCommand "all-systems" {} (''
          mkdir $out
        ''
        + (builtins.concatStringsSep "\n" (mapAttrsToList (
            name: config: ''
              ln -s ${config.config.system.build.toplevel} $out/${name}
            ''
          )
          self.nixosConfigurations)));
    };
}
