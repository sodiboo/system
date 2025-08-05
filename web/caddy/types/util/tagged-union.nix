{ lib, config, ... }:
let
  make-tagged-union =
    {
      loc,
      tag,
      variants,
    }:
    let
      tag-disambiguation = lib.types.submodule {
        options.${tag} = lib.mkOption {
          type = lib.types.enum (builtins.attrNames variants);
        };
        freeformType = lib.mkOptionType {
          name = "ignored";
          description = "ignored";
          descriptionClass = "noun";
          merge = loc: defs: { };
        };
      };

      resulting-type = lib.mkOptionType {
        name = "tagged-union";

        description = "tagged union, disambiguated by `${tag}`";
        descriptionClass = "nonRestrictiveClause";

        check = builtins.isAttrs;
        merge = loc: defs: variants.${(tag-disambiguation.merge loc defs).${tag}}.merge loc defs;

        nestedTypes = variants;
      };

      # short-circuit the assertion chain per variant,
      # but if there are many variants with errors, print them all.

      variant-assertions = builtins.mapAttrs (
        variant-name: variant-type:
        let
          is-submodule = variant-type.name == "submodule";
          is-sparse-submodule = variant-type.name == "sparse-submodule";

          variant-type-loc = loc ++ [ variant-name ];
          where-variant-type = lib.showOption variant-type-loc;

          suboptions = variant-type.getSubOptions variant-type-loc;

          tag-option = suboptions.${tag};

          tag-option-loc = variant-type-loc ++ [ tag ];
          where-tag-option = lib.showOption tag-option-loc;

          showWrongType =
            type:
            "`${type.name}`" + lib.optionalString (type.description or null != null) " (${type.description})";
        in
        [
          {
            assertion = is-submodule || is-sparse-submodule;
            message = "type at ${where-variant-type} must be a `submodule`, but it is ${showWrongType variant-type}";
          }
          {
            # sparse submodule already ensures shorthand is config
            assertion = is-submodule -> variant-type.functor.payload.shorthandOnlyDefinesConfig;
            message = "submodule at ${where-variant-type} must set shorthandOnlyDefinesConfig = true in `submoduleWith` invocation";
          }
          {
            assertion = suboptions ? ${tag};
            message = "submodule at ${where-variant-type} must have a `${tag}` suboption (with a type of `enum [ \"${variant-name}\" ]`)";
          }
          {
            assertion = tag-option ? _type;
            message = "option ${where-tag-option} is a set of options, but it must be an option (with a type of `enum [ \"${variant-name}\" ]`)";
          }
          {
            assertion = tag-option._type == "option";
            message = "option ${where-tag-option} must be of type `option`, but it is `${tag-option._type}`";
          }
          {
            assertion = tag-option ? type;
            message = "option ${where-tag-option} must have an option type";
          }
          {
            assertion = tag-option.type.name == "enum";
            message = "option ${where-tag-option} must be a singular enum (with value: \"${variant-name}\"), but it is ${showWrongType tag-option.type}";
          }
          {
            assertion = tag-option.type.functor.payload.values == [ variant-name ];
            message = "option ${where-tag-option} must be a singular enum (with value: \"${variant-name}\"), but it is: ${tag-option.type.description}";
          }
          {
            # non-sparse only has required options
            assertion = is-sparse-submodule -> tag-option.required or false;
            message = "option ${where-tag-option} must be required";
          }
        ]
      ) variants;

      checked-assertions = lib.remove null (
        builtins.map (builtins.foldl' (
          error:
          if error != null then
            lib.const error
          else
            { assertion, message }: if assertion then null else message
        ) null) (builtins.attrValues variant-assertions)
      );
    in
    if checked-assertions != [ ] then
      throw (builtins.concatStringsSep "\n" checked-assertions)
    else
      resulting-type;

  tagged-union-declaration =
    tag:
    lib.mkOptionType {
      name = "tagged-union-declaration";
      description = "attrs of (submodule type with a required tag `${tag}`)";
      descriptionClass = "composite";
      check = builtins.isAttrs;
      merge =
        loc: defs:
        make-tagged-union {
          inherit loc tag;
          variants = (lib.types.attrsOf lib.types.optionType).merge loc defs;
        };
    };
in
{
  options.caddy.lib.types.tagged-union-declaration = lib.mkOption {
    type = lib.types.functionTo lib.types.optionType;
    default = tagged-union-declaration;
    readOnly = true;
  };
}
