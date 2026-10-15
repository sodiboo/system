{
  personal.home-shortcut = { pkgs, ... }: {
    browser.web-extensions = [
      {
        package = pkgs.firefox-addons.sidebery;
        default_area = "navbar";
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
        managed.settings = {
          groupLayout = "list";
          showNewTabBtns = false;
          moveNewTabParent = "first_child";
          moveNewTabButton = "start";
          moveNewTab = "start";
          pinnedTabsPosition = "top";
          pinnedTabsList = true;
          treeRmOutdent = "first_child";
          scrollThroughTabsSkipDiscarded = false;
          tabMiddleClick = "discard";
          tabMiddleClickCtrl = "none";
          tabCloseMiddleClick = "discard";
        };
        keybindings = {
          #  _execute_sidebar_action = "Ctrl+E";
          activate = "Alt+Space";
          reset_selection = "Alt+R";
          next_panel = "Alt+Period";
          prev_panel = "Alt+Comma";
          new_tab_on_panel = "Ctrl+T";
          new_tab_as_first_child = "Ctrl+Space";
          up = "Alt+PageUp";
          down = "Alt+PageDown";
          up_shift = "Alt+Shift+Up";
          down_shift = "Alt+Shift+Down";
          sel_tabs_branch = "Alt+Shift+Right";
          unload_tabs = "Alt+U";
          move_tabs_up = "Ctrl+Alt+Up";
          move_tabs_down = "Ctrl+Alt+Down";
          tabs_indent = "Ctrl+Alt+Right";
          tabs_outdent = "Ctrl+Alt+Left";
          move_tabs_to_panel_start = "Ctrl+Alt+Home";
          move_tabs_to_panel_end = "Ctrl+Alt+End";
          group_tabs = "Alt+G";

          # these conflict with hardcoded binds; see omni patch below
          switch_to_prev_tab = "Alt+Up";
          switch_to_next_tab = "Alt+Down";
        };
      }
    ];
    browser.userchrome.omni-patches = [
      # disable Alt+Up / Alt+Down keys that conflict with binds above
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
