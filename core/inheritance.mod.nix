{ profiles, ... }:
{
  carbon.imports = profiles.universal.modules;
  oxygen.imports = profiles.universal.modules;
  iridium.imports = profiles.universal.modules;

  sodium.imports = profiles.universal.modules ++ profiles.personal.modules;
  nitrogen.imports = profiles.universal.modules ++ profiles.personal.modules;
}
