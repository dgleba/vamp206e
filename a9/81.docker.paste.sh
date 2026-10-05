#!/usr/bin/env bash




# ---------------------------------------------------

# Install docker with ubuntu repository

# all in one. Just paste the stanza below into terminal...


sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1) \
&& \
sudo apt-get update \
&& \
sudo apt-get -y install     ca-certificates     curl     gnupg     lsb-release \
&& \
sudo install -m 0755 -d /etc/apt/keyrings \
&& \
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
&& \
sudo chmod a+r /etc/apt/keyrings/docker.asc \
&& \
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
#
sudo apt-get update \
&& \
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  \
&& \
sudo usermod -aG docker $USER ; 
#
sudo systemctl status docker;
docker --version ;
sudo docker run hello-world;





# ---------------------------------------------------

# Older. Use the above.


##  Docker problem


# I had error running docker-compose.
# posts indicated that uninstalling the distro supplied version and reinstalling would help. This fixed it.
# Run this file.

exec bash


cd;
# is this needed? Maybe already done? Run if need be.
#  export   fil=82docker.sh ; export pth=shc/acom ;  chmod +x $pth/$fil  ;  . $pth/$fil   2>&1 | tee -a ${fil}_log$(date +"__%Y-%m-%d_%H.%M.%S").log;

# ---------------------------------------------------


# done
