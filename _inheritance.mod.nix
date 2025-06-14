{systems, ...}: {
  oxygen.imports = systems.universal.modules;
  iridium.imports = systems.universal.modules;

  sodium.imports = systems.universal.modules ++ systems.personal.modules;
  nitrogen.imports = systems.universal.modules ++ systems.personal.modules;
}
