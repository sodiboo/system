{ profiles, ... }:
{
  iridium.containers.plutonium = {
    ephemeral = true;
    autoStart = true;

    extraFlags = ["--timezone=off"]; # already set anyways

    config.imports = profiles.plutonium.modules;
  };

  plutonium.boot.isNspawnContainer = true;
}
