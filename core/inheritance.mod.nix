{ profiles, ... }:
{
  carbon.imports = profiles.universal.modules ++ profiles.physical.modules;
  oxygen.imports = profiles.universal.modules ++ profiles.physical.modules;
  iridium.imports = profiles.universal.modules ++ profiles.physical.modules;

  sodium.imports =
    profiles.universal.modules ++ profiles.physical.modules ++ profiles.personal.modules;
  nitrogen.imports =
    profiles.universal.modules ++ profiles.physical.modules ++ profiles.personal.modules;
}
