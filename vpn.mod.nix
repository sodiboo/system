{
  secrets,
  pki,
  ...
}: {
  # !! UNDER CONSTRUCTION !!
  # This was originally for connecting an Android device to my home network.
  # Most of it is from around january, probably (timestamp is missing). It predates my flakes migration.
  # I gave up on connecting my phone. Now, i'm aiming to connect my laptop to my home network.
  # But if you're reading this and it's the latest commit, then i'm still working on making that happen.
  sodium.modules = [
    ({
      config,
      lib,
      pkgs,
      ...
    }: let
      # carbon in PKI is the CA
      # sodium is the server
      # carbon and sodium live on the same machine. (they were roommates <3)
      # all others are clients. currently only lithium
      stunnel_port = null;

      # sudo openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj '/CN=127.0.0.1/O=localhost/C=US' -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
      # sudo chmod 600 /etc/stunnel/stunnel.pem
      stunnel = /etc/stunnel/stunnel.pem;

      # ./easyrsa init-pki
      # ./easyrsa build-ca # Common Name = carbon
      # ./easyrsa build-server-full sodium
      # ./easyrsa build-client-full lithium
      # ./easyrsa gen-dh
      # openssl pkcs12 -export -in ./pki/issued/lithium.crt -inkey ./pki/private/lithium.key -certfile ./pki/ca.crt -name lithium -out ./pki/lithium.p12
      # -> ./pki contains all the good stuff.
      #
      # (move ./pki/ca.crt, ./pki/dh.pem, and ./pki/issued/*.crt to /etc/openvpn/pki)
      # (move ./pki/private/*.key to /etc/openvpn/pki/private)
      # (transfer ./pki/lithium.p12 to Android device)
      #
      # sudo chmod 644 -R /etc/openvpn/pki/
      # sudo chmod 600 -R /etc/openvpn/pki/private
      #
      # (import this file to configuration.nix)
      # (transfer /etc/openvpn/lithium.ovpn to Android device)
      # (import lithium.p12 to OpenVPN Connect)
      # (import lithium.ovpn to OpenVPN, selecting lithium certificate)
      # pki = "${secrets}/.pki";

      remote = "vpn.sodi.boo";
      # subnet of my home network
      subnet = "192.168.86.0";

      tun = "tun0";
      eth = "enp3s0";

      openvpn_port = 1194;
      openvpn_proto = "tcp";

      use_stunnel = stunnel_port != null;
      nat_port =
        if stunnel_port != null
        then stunnel_port
        else openvpn_port;
      nat_proto =
        if stunnel_port != null
        then "TCP"
        else lib.toUpper openvpn_proto;
      client_remote =
        if use_stunnel
        then "127.0.0.1"
        else remote;

      ignore = x: "";
    in {
      # suo systemctl start nat
      networking.nat = {
        enable = true;
        externalInterface = eth;
        internalInterfaces = [tun];
        extraCommands = ''
          iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${eth} -j MASQUERADE
        '';
      };
      networking.firewall.trustedInterfaces = [tun];
      networking.firewall."allowed${nat_proto}Ports" = [nat_port];
      environment.systemPackages = with pkgs; [openvpn openssl];
      services.stunnel.enable = use_stunnel;
      services.stunnel.servers.openvpn = {
        accept = stunnel_port;
        cert = "${pki}/sodium.crt";
        key = "${pki}/private/sodium.key";
        connect = openvpn_port;
      };
      services.openvpn.servers.sodium.config =
        ''
          dev ${tun}

          server 10.8.0.0 255.255.255.0
          push "route ${subnet} 255.255.255.0"
          push "redirect-gateway def1"

          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"

          ca ${pki}/ca.crt
          dh ${pki}/dh.pem
          cert ${pki}/sodium.crt
          key ${pki}/private/sodium.key
          tls-auth ${pki}/private/ta.key

          port ${toString openvpn_port}
          proto ${openvpn_proto}
          cipher AES-256-CBC

          compress lz4-v2
          push "compress lz4-v2"

          key-direction 0
          keepalive 10 120
          persist-key
          persist-tun
        ''
        + ignore ''
          proto udp
          auth-nocache

          keepalive 10 60
          ping-timer-rem
        '';

      environment.etc."openvpn/lithium.ovpn" = {
        text = let
          f = name: path: "\n<${name}>\n${builtins.readFile (pki + path)}\n</${name}>\n";
        in
          ''
            dev tun
            client
            nobind

            remote "${client_remote}"
            port ${toString openvpn_port}
            proto ${openvpn_proto}
            cipher AES-256-CBC

            remote-cert-tls server
            resolv-retry infinite

            key-direction 1
            keepalive 10 120
            persist-key
            persist-tun
          ''
          + f "dh" /dh.pem
          + f "tls-auth" /private/ta.key
          # + f "ca" /ca.crt
          # + f "cert" /lithium.crt
          # + f "key" /private/lithium.key
          + ignore ''
            redirect-gateway def1

            auth-nocache

            comp-lzo
            keepalive 10 60
            nobind
          '';
        mode = "600";
      };
      system.activationScripts.openvpn-addkey = ignore ''
        f="/etc/openvpn/lithium.ovpn"
        if ! grep -q '<secret>' $f; then
          echo "appending secret key"
          echo "<secret>" >> $f
          cat ''${secret} >> $f
          echo "</secret>" >> $f
        fi
      '';
    })
  ];
}
