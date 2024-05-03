{
  sodium.modules = [
    {
      services.pipewire.wireplumber.extraConfig."99-rename" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {"node.name" = "alsa_output.usb-Razer_Razer_Nari-00.analog-game";}
            ];

            actions.update-props."node.nick" = "Razer Nari";
          }
          {
            matches = [
              {"node.nick" = "LC49G95T";}
            ];

            actions = {
              update-props = {
                "node.nick" = "Samsung Odyssey G9";
              };
            };
          }
        ];
      };
    }
  ];
}
