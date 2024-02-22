let
  settings = {
    keyboard_layout = "no";
    timezone = "Europe/Stockholm";
    language = "en_US.UTF-8";
    formats = "C.UTF-8";
  };

  module = {lib, ...}:
    with lib; {
      options.locale =
        mapAttrs (
          const (value:
            mkOption {
              type = types.str;
              readOnly = true;
              default = value;
            })
        )
        settings;
    };
in {
  shared.modules = [
    module
    ({config, ...}: {
      time.timeZone = config.locale.timezone;
      console.keyMap = config.locale.keyboard_layout;

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

      environment.variables."XKB_DEFAULT_LAYOUT" = config.locale.keyboard_layout;
    })
  ];

  shared.home_modules = [module];
}
