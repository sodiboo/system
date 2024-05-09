# !! UNDER CONSTRUCTION !!
# This was originally for connecting an Android device to my home network.
# Most of it is from around january, probably (timestamp is missing). It predates my flakes migration.
# I gave up on connecting my phone. Now, i'm aiming to connect my laptop to my home network.
# But if you're reading this and it's the latest commit, then i'm still working on making that happen.
{nixpkgs, ...}: let
  # carbon in PKI is the CA
  # sodium is the server
  # carbon and sodium live on the same machine. (they were roommates <3)
  # all others are clients. currently only lithium
  stunnel_port = null;
  client_stunnel_port = 1195;

  # sudo openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj '/CN=127.0.0.1/O=localhost/C=US' -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
  # sudo chmod 600 /etc/stunnel/stunnel.pem
  stunnel = /etc/stunnel/stunnel.pem;

  # ./easyrsa init-pki
  # ./easyrsa build-ca # Common Name = carbon
  # ./easyrsa build-server-full sodium
  # (store passphrase in /etc/openvpn/pki/private/sodium.pass)
  # ./easyrsa build-client-full lithium
  # (store passphrase in /etc/openvpn/pki/private/lithium.pass)
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
  pki = "/etc/openvpn/pki";

  remote = "vpn.sodi.boo";
  # subnet of my home network
  subnet = "192.168.86.0";

  tun = "tun0";
  eth = "eno1";

  openvpn_port = 1194;
  openvpn_proto = "tcp";

  # Okay, so this is fucking annoying.
  # One benefit of using a VPN is being able to access shit i need.
  #
  # Here's a portscan on my school network:
  #
  # $ for p in $(seq 65535); fish -c "if curl --connect-timeout 1 http://portquiz.net:$p >/dev/null 2>/dev/null; echo $p; end;" & end
  # 80
  # 110
  # 123
  # 143
  # 443
  # 500
  # 993
  # 995
  # 3389
  # 5222
  # 5223
  # 5228
  # 35061
  #
  # Sysadmins may be unhappy with spamming 2^16 requests, but fuck 'em. They don't even allow DNS and i don't wish for them to see everything i do.
  # So, at my home router, a rule routes (external 443) -> (sodium 1194)
  external_port = 443;

  use_stunnel = stunnel_port != null;
  nat_port =
    if use_stunnel
    then stunnel_port
    else openvpn_port;
  nat_proto =
    if use_stunnel
    then "TCP"
    else nixpkgs.lib.toUpper openvpn_proto;
  client_remote =
    if use_stunnel
    then "127.0.0.1"
    else remote;
  client_port = external_port;
  # if use_stunnel
  # then client_stunnel_port
  # else openvpn_port;

  # Networking invariants in above config:
  # - ${eth} is the ethernet interface on sodium.
  # - ${remote} is a public hostname that points to sodium.
  # - ${remote}:${nat_port} is forwarded to sodium.
  #
  # Filesystem invariants:
  #
  # The following files exist on sodium:
  # - ${pki}/ca.crt
  # - ${pki}/dh.pem
  # - ${pki}/sodium.crt
  # - ${pki}/private/sodium.key
  # - ${pki}/private/ta.key
  #
  # The following files exist on lithium:
  # - ${pki}/ca.crt
  # - ${pki}/lithium.crt
  # - ${pki}/private/lithium.key
  # - ${pki}/private/ta.key

  ignore = x: "";
in {
  sodium.modules = [
    ({
      config,
      lib,
      pkgs,
      ...
    }: {
      # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
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
      services.stunnel.servers.sodium = {
        cert = "/etc/stunnel/stunnel.pem";
        accept = stunnel_port;
        connect = openvpn_port;
      };
      services.openvpn.servers.sodium.config = ''
        dev ${tun}

        server 10.8.0.0 255.255.255.0
        push "route ${subnet} 255.255.255.0"
        push "redirect-gateway def1"

        push "dhcp-option DNS 1.1.1.1"
        push "dhcp-option DNS 1.0.0.1"

        port ${toString openvpn_port}
        proto ${openvpn_proto}
        cipher AES-256-GCM

        ca ${pki}/ca.crt
        dh ${pki}/dh.pem
        cert ${pki}/sodium.crt
        key ${pki}/private/sodium.key
        askpass ${pki}/private/sodium.pass
        tls-auth ${pki}/private/ta.key

        key-direction 0
        keepalive 10 120
        auth-nocache
        persist-key
        persist-tun
      '';
    })
  ];

  lithium.modules = [
    ({
      config,
      lib,
      pkgs,
      ...
    }: {
      services.stunnel.enable = use_stunnel;
      services.stunnel.clients.lithium = {
        accept = client_stunnel_port;
        connect = "${remote}:${toString stunnel_port}";
        cert = "/etc/stunnel/stunnel.pem";
      };
      services.openvpn.servers.lithium.config = ''
        dev tun
        client
        nobind

        remote "${client_remote}"

        remote-cert-tls server
        resolv-retry infinite

        port ${toString client_port}
        proto ${openvpn_proto}
        cipher AES-256-GCM

        ca ${pki}/ca.crt
        cert ${pki}/lithium.crt
        key ${pki}/private/lithium.key
        askpass ${pki}/private/lithium.pass
        tls-auth ${pki}/private/ta.key

        key-direction 1
        keepalive 10 120
        auth-nocache
        persist-key
        persist-tun
      '';
    })
  ];
}
