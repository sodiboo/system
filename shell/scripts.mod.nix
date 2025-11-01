{
  universal =
    {
      options,
      config,
      pkgs,
      lib,
      ...
    }:
    let

      apply =
        fn: loc: defs:
        fn loc (lib.mergeOneOption loc defs);

      script = lib.mkOptionType {
        name = "script";
        merge = apply (loc: script: pkgs.writeShellScript (lib.last loc) script);
      };
    in
    {
      options.scripts = lib.mkOption {
        description = "Collection of scripts used in my configuration.";
        type = lib.types.attrsOf script;
      };

      config.home-shortcut = {
        options.scripts = lib.mkOption {
          description = "Collection of scripts used in my configuration.";
          type = lib.types.attrsOf script;
        };

        config.scripts = lib.mkMerge (map lib.mkDefinition options.scripts.definitionsWithLocations);
      };
    };
}
