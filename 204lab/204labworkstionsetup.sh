#!/bin/bash
#by scanf
#setup 204lab workstation cloud compute node environment.
#System Required:  CentOS 7

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


clear
echo
echo "#############################################################"
echo "# One click Install kvm and webvirtcloud                    #"
echo "# Intro: https://www.scanfsec.com/                          #"
echo "# Author: scanf <scanf@scanfsec.com>                        #"
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

#setup python environment.
yum -y install python-virtualenv python-devel libvirt-devel glibc gcc nginx supervisor libxml2 libxml2-devel git python-pip
python -m pip install --upgrade pip

#downloading and install webvirtcloud 
mkdir /srv
git clone https://github.com/scanfsec/webvirtcloud /srv/webvirtcloud
python -m pip install -r /srv/webvirtcloud/conf/requirements.txt
cp /srv/webvirtcloud/conf/nginx/webvirtcloud.conf /etc/nginx/conf.d/
python /srv/webvirtcloud/manage.py migrate

#Configure the supervisor 
cat<<_EOF_>>/etc/supervisord.conf
[program:webvirtcloud]
command=gunicorn webvirtcloud.wsgi:application -c /srv/webvirtcloud/gunicorn.conf.py
directory=/srv/webvirtcloud
user=nginx
autostart=true
autorestart=true
redirect_stderr=true

[program:novncd]
command=python /srv/webvirtcloud/console/novncd
directory=/srv/webvirtcloud
user=nginx
autostart=true
autorestart=true
redirect_stderr=true
_EOF_
#Configure the nginx 
semanage fcontext -a -t httpd_sys_content_t "/srv/webvirtcloud(/.*)"
chown -R nginx:nginx /srv/webvirtcloud

cat<<_EOF_>/etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
_EOF_
#start nginx and supervisord.
systemctl restart nginx && systemctl restart supervisord
systemctl enable nginx && systemctl enable supervisord

#Selinux off
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#Firewall set
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=6080/tcp
firewall-cmd --reload

#add authorized_keys
mkdir ~/.ssh/
chmod 0700 ~/.ssh/
cat<<_EOF_>>~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6egAo9Fws/ULWy/98518SNlOkNnGbf/zwwzxSOJnOBnHKNs1NBK97tiqeyj/8GYgfVA+HDjKK2x6UGLPWZZiTwvmHAilX6Zt6AiPBrgTXIZPZW6hyDonRBi/+3P5LLTvq7QqIpWq6Ndsa8896otCRdW0g+uzD8UmIg7w0M45R/mphE/kh0VK0wqbXohtMhVmPCUcStTq21cLvLvEhR8xa5Zpe9kSAKytEAxgGwdvz0dyI0sYdMLtb8BxyGGFXj9rhNbOJas3gYJWVNRVOlRqbBpK7kxBL+/P6QVl/4AtNEGzp1prnqCHTGgeq6m8mWDh+6aXYO8/DJ6iYoD/ywYBX scanf@scanfsec.com
_EOF_
chmod 0600 ~/.ssh/authorized_keys

#Setup SSH Authorization. 
su - nginx -s /bin/bash -c "ssh-keygen  -t rsa -P '' -f /var/lib/nginx/.ssh/id_rsa"
su - nginx -s /bin/bash -c 'touch ~/.ssh/config && echo -e "StrictHostKeyChecking=no\nUserKnownHostsFile=/dev/null" >> ~/.ssh/config && chmod 0600 ~/.ssh/config'

echo "Install complete.\n"
echo -e "need use ssh-copy-id set ssh Authorization in to cloud compute node.\nexp:sudo su - nginx -s /bin/bash\nssh-copy-id webvirtmgr@qemu-kvm-libvirt-host"






