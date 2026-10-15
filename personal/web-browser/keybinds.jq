. + {commands: .commands + ($declared | map_values(
    {
        precedenceList: [
            {
                id: .addon,
                installDate:1000,
                value: { shortcut:.key },
                enabled:true,
            }
        ]
    }
) )}