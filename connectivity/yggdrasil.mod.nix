let
  public-peers-near-germany = [
    "quic://ygg1.mk16.de:1339?key=0000000087ee9949eeab56bd430ee8f324cad55abf3993ed9b9be63ce693e18a"
    "quic://ygg2.mk16.de:1339?key=000000d80a2d7b3126ea65c8c08fc751088c491a5cdd47eff11c86fa1e4644ae"
    "quic://nl1.route172.de:65535?key=000000002643ae27bad63e2a81f1d30554ce9ea634f5990062a9e079e23593cd"
  ];

  public-peers-near-sweden = [
    "quic://sto01.yggdrasil.hosted-by.skhron.eu:8885?key=ce8cfa43b8c9e71c1fe31832b39403f23166f2bac12d52c755d9ac68f55da81c"
    "quic://se.laerad.top:54001?key=29512833cbca43f1f0bb1833d0edcb45791e66f7955c577b57fd0fc78892e2f8"
    "quic://no0.yggdrasil.netralex.com:65535?key=f4b9fe4f9923834b1c20f84e13b14d90ecde443f78613ec54cf484eea6880fea"
  ];
in

{
  universal = { lib, config, ... }: {
    services.yggdrasil = {
      enable = lib.mkDefault config.vpn.enable;
      group = "wheel";

      openMulticastPort = true;

      settings = {
        IfName = "yggdrasil";

        Peers = lib.mkDefault public-peers-near-sweden;

        MulticastInterfaces = [
          {
            Beacon = true;
            Listen = true;
            Port = 0;
            # Password = "songbird";
          }
        ];
      };
    };
  };

  oxygen.services.yggdrasil = {
    persistentKeys = true;
    settings.Peers = public-peers-near-germany;
  };
}
