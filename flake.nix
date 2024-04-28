{
  description = "sodi flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    niri.url = "github:sodiboo/niri-flake";
    # niri-working-tree.url = "github:sodiboo/niri";
    # niri-working-tree.flake = false;

    secrets.url = "/etc/nixos/secrets";
    secrets.flake = false;
    nari.url = "github:sodiboo/nixos-razer-nari";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    secrets,
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

      is-dotfile = flip pipe [
        (splitString "/")
        last
        (hasPrefix ".")
      ];

      # `const` helper function is used extensively: the function is constant in regards to the name of the attribute.

      params =
        inputs
        // {
          secrets = (mapAttrs (const (p:
            if is-dotfile p
            then null
            else fileContents p))) (read_dir_recursively "${secrets}");
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

      raw_configs =
        builtins.zipAttrsWith (const (builtins.foldl' merge {})) (attrValues (read_all_modules "${self}"));

      configs = mapAttrs (const (merge raw_configs.shared)) (builtins.removeAttrs raw_configs ["shared"]);
    in {
      # for use in nix repl
      p = s: builtins.trace "\n\n${s}\n" "---";

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      nixosConfigurations = builtins.mapAttrs (const (config:
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
      configs;
    };
}
