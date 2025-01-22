# ALE Cloud Connect VPN 
## using Debian/Linux as VPN server 
To get ALEs Cloud Connect VPN function into operation may be a bit complicated for two wire guys. The following document shows the principle how you can get it running on
a Debian system as VPN jump host. This sample setup is able to handle the VPN connection for one PBX system at once. Its just for demonstration of the 
principles. Use it on your own risk!

### Prerequisites
- public IP address (DNAT 500,4500/udp doesn't work)
- a machine running Debian (tested with Debian 12)
- ALE CC Login and PBX installer password
- PBX must reach your VPN endpoint on udp ports 500 and 4500 via internet
- Windows PC with PuTTY installed

### Limitations
This setup works for OXO connect software up to R6.1/025.001. Rel 6.2 is currently unable to perform the EAP login.

### Debian
the minimal Software installation netinstall including ssh may match our needs. 

Login to your Debian, gain root rights, install sudo and the VPN software
```
su -
```
```
apt install sudo strongswan-charon libstrongswan-extra-plugins libcharon-extra-plugins iptables
```

create a new user for the following steps, change the identity to that user, assign group sudo, change dir to home directory
```
adduser ccvpn
```
```
adduser ccvpn sudo
```
```
su ccvpn
```
```
cd ~
```

### Configuration

Create a certificate authority (CA), for that copy+paste the following commands
```
mkdir -v ~/ca
```
```
cd ~/ca
```
```
openssl req -x509 \
            -sha256 -days 365 \
            -nodes \
            -newkey rsa:3072 \
            -subj "/C=DE/O=installer/OU=ALE-OXO-CC-CA/L=HAL/ST=ST/CN=ALE-OXO-Cloud-Connect-CA" \
            -keyout oxo-connect-CA.key -out oxo-connect-CA.crt
```

Copy the generated file oxo-connect-CA.crt to your Windows-PC. That can be done on your PC using PowerShell or Cmd and the following command line
(replace linux-ip-address with the IP of your Linux machine, pscp ccvpn@80.81.82.83:~/ca...):
```
pscp ccvpn@linux-ip-address:ca/oxo-connect-CA.crt "$env:USERPROFILE\Downloads"
```
➡️ import file oxo-connect-CA.crt from your Downloads folder into your PBX using WebDiag in Certificate / Trust Store / additional Authorities and perform a PBX warm restart. 

back on your linux shell 
Leave the ccvpn user session to fall back into your root shell 

```
exit
```
```
cd /home/ccvpn/ca
```

create now a server private key and public certificate for your VPN endpoint.
```
cat > csr.conf <<EOF
[ req ]
default_bits = 3072
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = DE
OU = Alcatel-Lucent Enterprise OXO Connect Maintenance
CN = oxo-connect
[ req_ext ]
EOF
```
```
openssl req -new -keyout vpn-server.key -newkey rsa:3072 -out vpn-server.csr \
        -nodes -subj "/C=DE/O=installer/OU=ALE-OXO-CC/L=HAL/ST=ST/CN=oxo-connect-vpn-server" \
        -config csr.conf
```

In the next text block you need to alter at least IP.1 and fill in your <mark>own</mark> public IPv4 address the linux box has. Definitions for IP.2, DNS.1 and DNS.2 are optional.
```
cat > cert.conf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.8.2.2
subjectAltName = @alt_names

[alt_names]
DNS.1 = myfritz-or-whatever.dns.name1.de
DNS.2 = optional-2nd-name.sn.mynetname.net
IP.1 = 80.81.82.83
IP.2 = 2003:a:1234:5678::
#      ^^^ substitude with your name(s) and IP(s)
EOF
```
```
openssl x509 -req \
    -in vpn-server.csr \
    -CA oxo-connect-CA.crt -CAkey oxo-connect-CA.key \
    -CAcreateserial -out vpn-server.crt \
    -days 365 \
    -sha256 -extfile cert.conf
```

put the files on its places
```
cp -v vpn-server.key /etc/ipsec.d/private
cp -v vpn-server.crt /etc/ipsec.d/certs
cp -v oxo-connect-CA.crt /etc/ipsec.d/cacerts
```

define your individiual credentials. Pleaase choose own passwords!
```
cat >> /etc/ipsec.secrets <<EOF
 : RSA vpn-server.key
 oxo-connect : EAP AoTahsh4ieK7hu7c
 # ^ line above contains the credentials from steps 7 and 8
 windows11 : EAP some-secure-pwd
 # change password ^^^^^^^^^!
EOF
```

in the next step we create a sample VPN config for strongswan:
```
cat >> /etc/ipsec.conf <<EOF
conn v2_eap+pubkey
	keyexchange = ikev2
	reauth = yes
	mobike = yes
	installpolicy = yes
	type = tunnel
	dpdaction = clear
	dpddelay = 120s
	dpdtimeout = 480s
	right = %any
	rightid = %any
	leftid = "C=DE, O=installer, OU=ALE-OXO-CC, L=HAL, ST=ST, CN=oxo-connect-vpn-server"
	ikelifetime = 28800s
	lifetime = 3600s
	rightsourceip = 10.168.92.100/31
	ike = aes256-sha256-ecp256
	esp = aes256-sha256-ecp256
	eap_identity = %identity
	leftauth = pubkey
	rightauth = eap-mschapv2
	leftcert = vpn-server.crt
	leftsendcert = always
	leftsubnet = 0.0.0.0/0
	auto = add
EOF
```
```
ipsec restart
```

enable IP forwarding and make it permanent
```
sysctl -w net.ipv4.ip_forward=1
```
```
sed -e 's/^#net\.ipv4\.ip_forward=1/net\.ipv4\.ip_forward=1/' -i /etc/sysctl.conf
```
```
iptables -t nat -A POSTROUTING -s 10.168.92.100/31 -m policy --dir out --pol none -j MASQUERADE
```
```
apt install iptables-persistent
```

### Cloud Connect
Now go to the Could Connectivity control page using  https://oxo-connectivity.al-enterprise.com
1. Login using a CC-ID and installer Password of one your PBXes
2. click Connectivity
3. Manage your VPN configuration profiles
4. name of the profile: v2_eap+pubkey
5. VPN gateway: public IP address of your linux (f.e. 80.81.82.83, must be the same as you enterend for IP.1)
6. IKE authentication method: v2_eap+pubkey
7. Login: select one, (f.e. oxo-connect)
8. Password: select one (f.e. AoTahsh4ieK7hu7c change this!)
9. Certificate: copy+paste the contents of file oxo-connect-CA.crt
10. Certificate subject: C=DE, O=installer, OU=ALE-OXO-CC, L=HAL, ST=ST, CN=oxo-connect-vpn-server
11. IKE port: 500
12. Nat-T port: 4500
13. Phase 1 DH group: 19
14. Phase 2 PFS group: 19
15. inactivity timeout (in minutes): 60
keep Peer ID empty and encryption and hash defaults.


### continue on your Windows PC 

Open a PowerShell session and copy+paste the following commands

Copy your self signed CA certificate from the Debian machine to your Windows 11 PC. I do this using PowerShell and PuTTY:
search for "PowerShell" and select "run as administrator". Replace linux-ip-address with the IP of your Linux machine.
```
pscp ccvpn@linux-ip-address:~/ca/oxo-connect-CA.crt "$env:USERPROFILE\Downloads"
```

import the CA certificate into your local machines root certificate store
```
$params = @{
    FilePath = "$env:USERPROFILE\Downloads\oxo-connect-CA.crt"
    CertStoreLocation = 'Cert:\LocalMachine\Root'
}
Import-Certificate @params
```

Create a new VPN connection on your installer PC. The command line is just an example you need to put the IP address of your Linux machine after the -ServerAddress parameter!

```
Add-VpnConnection -Name "v2_eap+pubkey" -ServerAddress 80.81.82.83 -TunnelType Ikev2 `
                  -EncryptionLevel Required -AuthenticationMethod Eap -RememberCredential -SplitTunneling -PassThru
```
it's important that ServerAddress is <mark>identical</mark> to the IP.1 or the DNS.1 values of your certificate!

Configure strong encryption for that VPN definition
```
Set-VpnConnectionIPsecConfiguration -ConnectionName "v2_eap+pubkey" -AuthenticationTransformConstants "SHA256" `
                                    -DHGroup "ECP256" -CipherTransformConstants "AES256" -PfsGroup "ECP256" `
                                    -EncryptionMethod "AES256" -IntegrityCheckMethod "SHA256" -PassThru
```
Start the Cloud Connect VPN for your PBX on the connections panel from https://oxo-connectivity.al-enterprise.com

Establish also the VPN connection on your Windows PC using the same username and password as your defined above (windows11 / your-changed-password) 

Now should both be connected. You may access from you Windows 11 PC to the address shown in the CC panel,
this should be https://10.168.92.100/services/webapp/monitor or use OMC on 10.168.92.100 to configure your PBX remotely.

I would strongly recommend adding more security to this Linux box. This can be done, for example, by using a bastion host firewall.
The following snippet is an UNTESTED example:

```
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I INPUT -m conntrack --ctstate INVALID,UNTRACKED -j DROP
iptables -A INPUT -p icmp -m limit --limit 2 --limit-burst 5 --icmp-type 8/0
iptables -A INPUT -p icmp -m limit --limit 3 --limit-burst 6 --icmp-type 3/3
iptables -A INPUT -p icmp -m limit --limit 1 --limit-burst 2 --icmp-type 3/4
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p udp -m multiport --dports 500,4500 -j ACCEPT
iptables -A INPUT -j DROP

iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD -m conntrack --ctstate INVALID,UNTRACKED -j DROP
iptables -A FORWARD -m policy --pol ipsec --dir in -j ACCEPT
iptables -A FORWARD -m policy --pol ipsec --dir out -j ACCEPT
iptables -A FORWARD -j DROP
```
```
service netfilter-persistent save
```
