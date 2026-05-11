# lib.types.nonEmptyStr counts whitespace as empty, which is undesirable
{ lib, ... }:
{
  options.lib.types.nonempty-str = lib.mkOption {
    type = lib.types.optionType;
    readOnly = true;
    default = lib.mkOptionType {
      name = "nonempty-str";
      description = "non-empty string";
      descriptionClass = "noun";
      check = v: builtins.isString v && v != "";
      merge = lib.options.mergeEqualOption;
    };
  };
}
