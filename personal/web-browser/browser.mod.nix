{
  personal.home-shortcut = { pkgs, ... }: {
    browser.preferences = {
      "general.autoScroll" = true;
      "middlemouse.paste" = false;

      "permissions.default.shortcuts" = 2; # block sites hijacking shortcuts by default
      "browser.startup.page" = 3; # restore tabs on startup

      "privacy.sanitize.sanitizeOnShutdown" = false; # don't log me out of everything

      # don't fuck with my dark theme
      "privacy.resistFingerprinting" = false;
      # but i'd still like to have some anti-fingerprinting measures
      "privacy.fingerprintingProtection" = true;
      "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";

      # we can have the full RFP in private browsing mode, though.
      "privacy.resistFingerprinting.pbmode" = true;

      "browser.nova.enabled" = true;
      "sidebar.revamp" = true;
      "sidebar.verticalTabs" = true;
      "browser.tabs.inTitlebar" = 1;
    };

    browser.policies = {
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

    browser.extensions = {
      ublock-origin = {
        private_browsing = true;
        default_area = "navbar";
      };
      sidebery.default_area = "navbar";
      bitwarden.default_area = "navbar";
      darkreader = {
        package = pkgs.callPackage ./darkreader.nix { };
        default_area = "navbar";
        managed = {
          # this feature is incredibly broken and causes horrifying problems that only bother a web developer
          detectDarkTheme = false;
          # most sites have a dark theme these days, and since we're not detecting that, don't try to apply darkreader also by default.
          enabledByDefault = false;

          previewNewDesign = true;
        };
      };

      libredirect.default_area = "navbar";
      consent-o-matic = { };
      fastforwardteam = { };
      indie-wiki-buddy = { };

      sponsorblock = { };
      return-youtube-dislikes = { };
      dearrow = { };
    };
  };
}
