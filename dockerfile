FROM ubuntu:22.04

#Instalamos sudo
RUN apt-get update && apt-get -y install sudo

#Creamos un usuario
ARG USER=franpc
ARG PASS="qwerty1234"
RUN useradd -m -s /bin/bash $USER && echo "$USER:$PASS" | chpasswd
RUN usermod -aG sudo franpc
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER franpc
WORKDIR /home/franpc
RUN whoami
RUN sudo whoami

#Para poder usar add-apt-repository
RUN sudo apt -y update
RUN sudo apt -y install software-properties-common
RUN sudo apt -y update

#Instalar timeshift
RUN sudo add-apt-repository -y ppa:teejee2008/timeshift
RUN sudo apt-get -y update
RUN sudo apt-get -y install timeshift

#Instalar gparted
RUN sudo apt -y install gparted

#Instalar htop
RUN sudo apt-get -y install htop

#Instalar nftables
#RUN sudo apt -y install nftables

#Was kernel compiled without the nftables module?
#RUN sudo apt-get install kmod
#RUN sudo lsmod | grep nf_tables

#Dar permisos nftables
#RUN sudo chmod 777 /etc/nftables.conf

#RUN sudo printf "#!/bin/bash \
#\nsudo nft add table inet my_table \
#\nsudo nft add chain inet my_table my_input '{ type filter hook input priority 0 ; policy accept ; }' \
#\nsudo nft add chain inet my_table my_tcp_chain \
#\nsudo nft add rule inet my_table my_input ct state related,established accept \
#\nsudo nft add rule inet my_table my_input iif lo accept \
#\nsudo nft add rule inet my_table my_input 'meta l4proto tcp tcp flags & (fin|syn|rst|ack) == syn ct state new jump my_tcp_chain' \
#\nsudo nft add rule inet my_table my_tcp_chain tcp dport 22 accept \
#\nsudo nft list ruleset > /etc/nftables.conf \n" > /home/franpc/nftables.sh

#Instalar IPTables
RUN sudo apt-get -y install iptables

#Instalar nmap
RUN sudo apt -y install nmap

#Instalar openssh-server
RUN sudo apt-get -y install openssh-server

#Instalar GNOME
RUN sudo apt -y update
RUN sudo DEBIAN_FRONTEND=noninteractive apt install ubuntu-gnome-desktop -y

#Instalamos el inicio de sesión Xfce4
RUN sudo apt-get update
RUN sudo apt-get install apt-utils
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install xfce4 -y
RUN sudo apt-get install xfce4-goodies -y

USER root

#Configuramos el default login bajo xfce4
RUN sudo printf "[InputSource0] \
\nxkb=us \
\n \
\n[User] \
\nXSession=xfce \
\nBackground=/usr/share/backgrounds/xfce/xfce-teal.jpg \
\nSystemAccount=false \n" > /var/lib/AccountsService/users/franpc

USER franpc
WORKDIR /home/franpc

#Instalamos nano
RUN sudo apt-get install nano -y

#Configuramos openssh-server
RUN sudo sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
RUN sudo sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/g' /etc/ssh/sshd_config
RUN sudo sed -i 's/#X11UseLocalhost yes/X11UseLocalhost yes/g' /etc/ssh/sshd_config

#Instalamos y configuramos el servidor VNC, y el autocutsel
RUN sudo apt-get -y update
RUN sudo apt-get -y install autocutsel
RUN sudo apt -y install tightvncserver

USER root

#Automatizamos la configuración de VNC
#Script para generar las password de VNC

#RUN sudo printf "#!/bin/bash \
#\nmyuser="franpc" \
#\nmypasswd="qwerty1234" \
#\nsudo mkdir /home/$myuser/.vnc \
#\nsudo echo $mypasswd | vncpasswd -f > /home/$myuser/.vnc/passwd \
#\nsudo chown -R $myuser:$myuser /home/$myuser/.vnc \
#\nsudo chmod 0600 /home/$myuser/.vnc/passwd \n" > /init-tightvncserver-config.sh

RUN sudo printf "#!/bin/bash \
\nmypasswd="qwerty1234" \
\nsudo mkdir /root/.vnc \n" > /init-tightvncserver-config1.sh
#\nsudo echo "qwerty1234 qwerty1234 N" | vncpasswd -f > /root/.vnc/passwd \
#\nsudo chown -R $myuser:$myuser /home/$myuser/.vnc \
#sudo chmod 0600 /root/.vnc/passwd \n" > /init-tightvncserver-config1.sh

RUN chmod +x /init-tightvncserver-config1.sh
RUN sudo /init-tightvncserver-config1.sh

RUN printf "qwerty1234\nqwerty1234\n\n" | vncpasswd
RUN sudo chmod 0600 /root/.vnc/passwd

#Generar el archivo xstartup
RUN sudo printf "#!/bin/bash \
\n/usr/bin/autocutsel -s CLIPBOARD -fork \
\nxrdb $HOME/.Xresources \
\nstartxfce4 & \n" > /root/.vnc/xstartup

RUN chmod +x /root/.vnc/xstartup

#Preparamos el script para lanzar el ssh
RUN sudo printf "#!/bin/bash \
\nsudo ssh-keygen -A \
\nsudo service ssh start \n" > /init-ssh.sh

RUN chmod +x /init-ssh.sh

#Automatizamos inicio VNC Server
#RUN sudo echo "DISPLAY=localhost:1" >> /etc/environment
#RUN sudo sed -i 's/env_reset/env_keep = "DISPLAY"/g' /etc/sudoers

#RUN sudo printf "export DISPLAY=localhost:1 \n" > /etc/profile.d/myenvvars.sh
#RUN chmod +x /etc/profile.d/myenvvars.sh

RUN sudo printf "#! /usr/bin/env bash \
\nexport DISPLAY=localhost:1 \n" > /export.bash

RUN sudo printf "#!/bin/bash \
\n/usr/bin/vncserver -kill :1 > /dev/null 2>&1 \
\nsudo /usr/bin/vncserver -depth 16 -geometry 1024x768 -localhost \
\nsource /export.bash \
\necho "DISPLAY" \
\necho \$DISPLAY \
\necho "\End" \
\nsudo xhost + \
\nsudo xauth list "\$DISPLAY" \n" > /init-vncserver.sh

RUN sudo chmod 777 /export.bash
RUN sudo chmod 777 /init-vncserver.sh

#USER franpc
#WORKDIR /home/franpc

RUN echo 'export DISPLAY=localhost:1' >> ~/.bashrc

#Instalamos un Web Browser
#RUN sudo add-apt-repository ppa:savoury1/chromium -y
#RUN sudo add-apt-repository ppa:savoury1/ffmpeg4 -y
#RUN sudo apt-get update
#RUN sudo apt install chromium-browser -y

#RUN sudo apt-get update -y
#RUN sudo apt-get install dpkg -y
#RUN sudo apt update -y
#RUN sudo apt upgrade -y
#RUN sudo apt install wget -y
#RUN sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#RUN sudo dpkg -i /home/franpc/google-chrome-stable_current_amd64.deb

RUN sudo add-apt-repository ppa:mozillateam/ppa -y
RUN sudo apt -y update
RUN sudo apt -y install -t 'o=LP-PPA-mozillateam' firefox firefox-locale-es
RUN sudo apt -y install ffmpeg
#sudo firefox

RUN sudo printf "#!/bin/bash \
\nsource /export.bash \
\nsudo firefox  \n" > /open-firefox.sh

RUN sudo chmod 777 /open-firefox.sh

RUN echo "root:qwerty1234" | chpasswd

ENTRYPOINT /init-ssh.sh && /init-vncserver.sh && /open-firefox.sh && bash