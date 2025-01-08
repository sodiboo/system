{
  personal.modules = [
    {
      # Bluetooth audio devices come with multiple profiles:
      # One important profile is the "headset" profile, which has a microphone (as opposed to headphones with no mic)
      # and the other is the Advanced Audio Distribution Profile (A2DP), which is used for high quality audio.
      # The headset profile has absolutely terrible audio quality, and i never want to use it.
      # And, my computer has a separate microphone anyway, so i don't need the headset profile's microphone.
      # Let's just never switch to the headset profile.
      services.pipewire.wireplumber.extraConfig."51-mitigate-annoying-profile-switch" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };
    }
  ];

  sodium.modules = [
    {
      services.pipewire.wireplumber.extraConfig."99-rename" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {"node.name" = "alsa_output.usb-Razer_Razer_Nari-00.analog-game";}
            ];

            actions = {
              update-props = {
                # This will be my default output device usually.
                # I want waybar to show this as "Razer Nari"
                "node.nick" = "Razer Nari";
                # By the default, these names are shown side by side in wpctl status.
                # So i don't want to have one look different from the other.
                "node.description" = "Razer Nari (Game)";
              };
            };
          }
          {
            matches = [
              {"node.name" = "alsa_output.usb-Razer_Razer_Nari-00.analog-chat";}
              # It just so happens that i want the microphone to have the same props as output.
              # The rest of comments are about the output.
              {"node.name" = "alsa_input.usb-Razer_Razer_Nari-00.analog-chat";}
            ];

            actions = {
              update-props = {
                # I want the chat output to be distinguished in waybar though.
                # It is not the default, so it gets the qualified name.
                # This is the default set by my nari module, but i'm specifying it here to express my intent.
                "node.nick" = "Razer Nari (Chat)";
                # The default descriptions are fine: "Nari (Wireless) Game" / "Nari (Wireless) Chat"
                # But i prefer this format. It also matches better with the node.nick i've set.
                "node.description" = "Razer Nari (Chat)";
              };
            };
          }
          {
            matches = [
              # Matching the model number of the monitor instead of the node name.
              # This is done to ensure that it is based on the monitor and not the port.
              {"node.nick" = "LC49G95T";}
            ];

            actions = {
              update-props = {
                # Again, i want to show the name in waybar rather than the model number.
                "node.nick" = "Samsung Odyssey G9";
                # Without an override, the description will be "Navi 31 HDMI/DP Audio Digital Stereo (HDMI)"
                # Which is unhelpful, and also wrong. This monitor is plugged in via DP.
                "node.description" = "Samsung Odyssey G9";
              };
            };
          }
          {
            matches = [
              # not sure what this is.
              {"node.name" = "alsa_output.pci-0000_6b_00.6.iec958-stereo";}
              {"node.name" = "alsa_input.pci-0000_6b_00.6.analog-stereo";}
              {"device.name" = "alsa_card.pci-0000_6b_00.6";}
            ];

            actions = {
              update-props = {
                "node.disabled" = true;
              };
            };
          }
        ];
      };
    }
  ];

  nitrogen.modules = [
    {
      services.pipewire.wireplumber.extraConfig."99-rename" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {"node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo";}
              {"node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo";}
            ];

            actions = {
              update-props = {
                "node.nick" = "Built-in Audio";
                "node.description" = "Built-in Audio";
              };
            };
          }
        ];
      };
    }
  ];
}
