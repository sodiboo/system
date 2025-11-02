{
  universal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.powerline-go = {
        enable = true;
        settings.hostname-only-if-ssh = true;
        settings.duration-min = 20; # seconds
        modules = [
          "host"
          "cwd"
          "perms"
          "git"
          "hg"
          "nix-shell"
          "jobs"
          "duration"
          "exit"
          "root"
        ];
      };

      programs.nushell.extraConfig =
        let
          cfg = config.programs.powerline-go;

          # This whole let block exists purely because `commandLineArguments` is not exposed by home-manager.
          # It's this, verbatim: https://github.com/nix-community/home-manager/blob/c0016dd14773f4ca0b467b74c7cdcc501570df4b/modules/programs/powerline-go.nix#L17-L53
          valueToString =
            value:
            if builtins.isList value then
              builtins.concatStringsSep "," (builtins.map valueToString value)
            else if builtins.isAttrs value then
              valueToString (lib.mapAttrsToList (key: val: "${valueToString key}=${valueToString val}") value)
            else
              builtins.toString value;
          modulesArgument = lib.optionalString (cfg.modules != null) " -modules ${valueToString cfg.modules}";
          modulesRightArgument = lib.optionalString (
            cfg.modulesRight != null
          ) " -modules-right ${valueToString cfg.modulesRight}";
          evalMode = cfg.modulesRight != null;
          evalArgument = lib.optionalString evalMode " -eval";
          newlineArgument = lib.optionalString cfg.newline " -newline";
          pathAliasesArgument = lib.optionalString (
            cfg.pathAliases != null
          ) " -path-aliases ${valueToString cfg.pathAliases}";
          otherSettingPairArgument =
            name: value: if value == true then " -${name}" else " -${name} ${valueToString value}";
          otherSettingsArgument = lib.optionalString (cfg.settings != { }) (
            lib.concatStringsSep "" (lib.mapAttrsToList otherSettingPairArgument cfg.settings)
          );
          commandLineArguments = ''
            ${evalArgument}${modulesArgument}${modulesRightArgument}${newlineArgument}${pathAliasesArgument}${otherSettingsArgument}
          '';
        in
        ''
          def left_prompt [] {
            ${lib.getExe cfg.package} -error $env.LAST_EXIT_CODE -duration (($env.CMD_DURATION_MS | into duration --unit ms) / 1sec) -jobs (job list | length) ${commandLineArguments}
          }

          $env.PROMPT_COMMAND = { || left_prompt }
          $env.PROMPT_INDICATOR = ""
        '';
    };
}
