{
  personal.home-shortcut =
    { lib, pkgs, ... }:
    {
      stylix.targets.librewolf.enable = false;
      programs.librewolf = {
        enable = true;

        policies = {
          Preferences =
            builtins.mapAttrs
              (_: Value: {
                inherit Value;
                Locked = true;
              })
              {
                "general.autoScroll" = true;
                "middlemouse.paste" = false;
                "permissions.default.shortcuts" = 2; # block sites hijacking shortcuts by default
              };
          AIControls = {
            # most of these are actively harmful anti-features
            Default = {
              Value = "blocked";
              Locked = true;
            };

            # these serve legitimate accessibility purposes
            Translations.Locked = false;
            PDFAltText.Locked = false;
            SpeechRecognition.Locked = false;

            # i use this one all the time!
            Translations.Value = "available";

            # i don't need this and i don't want an AI to perceive for me, with its biases
            # alt text *is* inherently subjective. i don't want that from AI.
            PDFAltText.Value = "blocked";

            # speech recognition seems more objective.
            # there's only one correct way to transcribe most speech
            # unless, it's like, a pun that only works due to homophones (then there are multiple correct ways to write it down and all of them are wrong)
            # i'm also somewhat hard of hearing. so i don't want to block this feature from myself.
            # also, this is a Web API?? am i crazy? this is not a Browser AI Feature this is a standard thing. these controls are supposed to be for firefox-specific nags!!
            # tell me i'm not crazy. this page lists firefox-specific docs for all but speech recognition! https://support.mozilla.org/en-US/kb/firefox-ai-controls
            SpeechRecognition.Value = "available";
          };
        };
        profiles.sodiboo = {
        };
      };
    };
}
