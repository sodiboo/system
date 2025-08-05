{ lib, config, ... }:
let
  sparse-submodule =
    let
      name = "sparse-submodule";

      eval-sparse-options =
        let
          eval-set =
            options:
            builtins.concatMap (
              name:
              let
                item = options.${name};
              in
              if lib.isOption item then eval-option name item else eval-group name item
            ) (builtins.attrNames options);

          eval-option =
            name: option:
            let
              internal = option.internal or false;
              required = option.required or false;
              defined = option.isDefined;
            in
            if !internal && (required || defined) then [ (lib.nameValuePair name option.value) ] else [ ];

          eval-group =
            name: options:
            let
              suboptions = eval-set options;
            in
            if suboptions != [ ] then [ (lib.nameValuePair name (builtins.listToAttrs suboptions)) ] else [ ];
        in
        options: builtins.listToAttrs (eval-set options);
    in
    { modules }:
    lib.mkOptionType {
      inherit name;
      description = "sparse submodule";
      descriptionClass = "noun";

      check = builtins.isAttrs;

      merge =
        prefix: defs:
        let
          eval = lib.modules.evalModules {
            inherit prefix;
            modules =
              modules
              ++ map (def: {
                _file = def.file;
                config = def.value;
              }) defs;
          };
        in
        if eval._module.freeformType != null then
          throw "sparse submodule at ${lib.showOption prefix} can't have a freeform type"
        else
          eval-sparse-options (builtins.removeAttrs eval.options [ "_module" ]);

      emptyValue.value = { };

      getSubOptions =
        prefix:
        (lib.modules.evalModules {
          inherit prefix;
          modules = modules;
        }).options;

      getSubModules = modules;
      substSubModules = modules: sparse-submodule { inherit modules; };

      functor = lib.types.defaultFunctor name // {
        type = sparse-submodule;
        payload = { inherit modules; };
        binOp = lhs: rhs: {
          modules = lhs.modules ++ rhs.modules;
        };
      };
    };
in
{
  options.caddy.lib.types.sparse-submodule = lib.mkOption {
    type = lib.types.functionTo lib.types.optionType;
    readOnly = true;
    default =
      modules:
      sparse-submodule {
        modules = lib.toList modules;
      };
  };

  options.caddy.lib.mkRequiredOption = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = args: lib.mkOption args // { required = true; };
  };

  options.caddy.lib.mkSparseOption = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      options: lib.mkOption { type = sparse-submodule { modules = [ { inherit options; } ]; }; };
  };
}
