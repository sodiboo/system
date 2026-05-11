{ lib, ... }:
let
  config-directives-for-section =
    {
      knotc,
      section,
      options,
    }:
    lib.mkMerge [
      (lib.mkBefore [
        (knotc [
          "conf-set"
          "${section}"
        ])
      ])
      (config-directives-for-options { inherit knotc section options; })
    ];

  config-directives-for-options =
    {
      knotc,
      section,
      options,
    }:
    (lib.mkMerge (
      builtins.map (
        name:
        config-directive-for-option {
          inherit knotc section name;
          value = options.${name};
        }
      ) (builtins.attrNames options)
    ));

  config-directive-for-option =
    {
      knotc,
      section,
      name,
      value,
    }:
    lib.mkIf (value != null) [
      (knotc (
        [
          "conf-set"
          "${section}.${name}"
        ]
        ++ builtins.map (
          value:
          {
            string = value;
            int = toString value;
            float = toString value;
            bool = if value then "on" else "off";
          }
          .${builtins.typeOf value}
        ) (lib.toList value)
      ))
    ];
in

{
  options.lib.types =
    builtins.mapAttrs
      (
        _: type:
        lib.mkOption {
          type = lib.types.optionType;
          readOnly = true;
          default = type;
        }
      )
      rec {
        config-atom = lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.float
          lib.types.bool
        ];

        config-value = lib.types.either config-atom (lib.types.listOf config-atom);

        config-section = lib.types.attrsOf (lib.types.nullOr config-value);
      };

  options.lib.config-directives-for-section = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = config-directives-for-section;
  };

  options.lib.config-directives-for-options = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = config-directives-for-options;
  };

  options.lib.config-directive-for-option = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = config-directive-for-option;
  };
}
