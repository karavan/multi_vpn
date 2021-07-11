#!/usr/bin/env bash

## Configure repo openvpn. See https://community.openvpn.net/openvpn/wiki/OpenvpnSoftwareRepos
##
apt update && apt -y install ca-certificates wget curl net-tools gnupg lsb-release
wget -qO- https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/openvpn.list

## Install Openvpn
apt update && apt -y install openvpn


if [[ $(crontab -l | grep -vE "^[[:blank:]](#|$)" | grep -q 'some_command'; echo $?) == 1 ]]
then
    set -f
    echo $(crontab -l ; echo '* 1 * * * some_command') | crontab -
    set +f
fi
