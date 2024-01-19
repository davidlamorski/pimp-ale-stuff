# pimp-rainbow-webrtc-mgw
Just a few bash commands to customise the underlying Debian system under ALEs Rainbow WebRTC-Gateway. Login to your WebRTC-Gateway system using ssh and copy+paste following code blocks  to the systems command line.

Warning: The code below may destroy your WebRTC Gateway function and cause loss of support by ALE. For usage on non productive test systems only.

If you find it nice being able to just type "log" for continuously view of relevant logs. Stops with ctrl-c.
```
[ ! -f /usr/local/bin/log ] && ( echo -e "#\!/bin/sh\ntail -f /var/log/syslog /var/log/otlitemediapillargateway/portal.log /var/log/janus/janus.log\n" > /tmp/log ; sudo sed -e 's/^#\\/#/' -i /tmp/log ; sudo mv -vb /tmp/log /usr/local/bin/log ; sudo chmod -v +x /usr/local/bin/log; echo "alias log='sudo log'" >> ~/.bash_aliases )
```

Enrich your gateway with additional Debian packages 
```
[ ! -s /etc/apt/sources.list ] && ( LSB_REL=` lsb_release -s -c ` ; echo -e "deb http://ftp.de.debian.org/debian/ $LSB_REL main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ $LSB_REL main non-free contrib\n\ndeb http://security.debian.org/ $LSB_REL-security main non-free contrib\ndeb-src http://security.debian.org/ $LSB_REL-security main non-free contrib\n" > /tmp/sources.list ; sudo mv -vb /tmp/sources.list /etc/apt ; sudo chown -v 0:0 /etc/apt/sources.list ; sudo apt-get update )
```

Software packages I use on my Gateway
```
sudo apt-get update && sudo apt-get -y install imvirt screen ngrep \ ;
MACHINE=` sudo imvirt ` && if [[ $MACHINE == KVM ]]; then sudo apt-get -y install  qemu-guest-agent ; fi
```

Fitting locale settings
```
sudo sed -i -e 's/^#\ de_DE\.UTF-8/de_DE\.UTF-8/' /etc/locale.gen ; sudo dpkg-reconfigure tzdata locales ; \
grep XKBLAYOUT=\"us\" /etc/default/keyboard && sudo sed -e 's/\"us\"/\"de\"/' -i /etc/default/keyboard
```
