{
  personal.home-shortcut = { pkgs, ... }: {
    browser.web-extensions = [
      {
        package = pkgs.firefox-addons.sidebery;
        # permissions = [
        #   "activeTab"
        #   "tabs"
        #   "contextualIdentities"
        #   "cookies"
        #   "storage"
        #   "unlimitedStorage"
        #   "sessions"
        #   "menus"
        #   "menus.overrideContext"
        #   "search"
        #   "theme"
        #   "identity"
        # ];
      }
    ];
    browser.userchrome.js = [
      ./userChrome.js
    ];
    browser.userchrome.omni-patches = [
      ./disable-search-switch-keys.patch
    ];
    programs.librewolf = {
      policies.Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
      };
      profiles.sodiboo.userChrome = ./userChrome.css;
    };
  };
}
