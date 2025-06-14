let
  settings = {
    keyboard-layout = "no";
    timezone = "Europe/Stockholm";
    language = "en_US.UTF-8";
    formats = "C.UTF-8";
  };
in
{
  universal =
    {
      config,
      lib,
      ...
    }:
    {
      options.locale = lib.mapAttrs (lib.const (
        value:
        lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = value;
        }
      )) settings;

      config = {
        time.timeZone = config.locale.timezone;
        console.keyMap = config.locale.keyboard-layout;

        i18n.defaultLocale = config.locale.language;
        i18n.extraLocaleSettings = {
          LC_ADDRESS = config.locale.formats;
          LC_IDENTIFICATION = config.locale.formats;
          LC_MEASUREMENT = config.locale.formats;
          LC_MONETARY = config.locale.formats;
          LC_NAME = config.locale.formats;
          LC_NUMERIC = config.locale.formats;
          LC_PAPER = config.locale.formats;
          LC_TELEPHONE = config.locale.formats;
          LC_TIME = config.locale.formats;
        };

        environment.variables."XKB_DEFAULT_LAYOUT" = config.locale.keyboard-layout;
      };
    };
}
