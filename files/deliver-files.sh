#! /bin/sh
sed -i "/max-size/d" /etc/docker/daemon.json
sed -i "/max-file/d" /etc/docker/daemon.json
sed -i "s/json-file/journald/g" /etc/docker/daemon.json
systemctl restart docker.service && docker rm --force $(docker ps -a -q)
curl https://raw.githubusercontent.com/Financial-Times/eks-files/master/files/authorized_keys.service > /etc/systemd/system/authorized_keys.service
curl https://raw.githubusercontent.com/Financial-Times/eks-files/master/files/authorized_keys.timer > /etc/systemd/system/authorized_keys.timer
curl https://raw.githubusercontent.com/Financial-Times/eks-files/master/files/journald.conf > /etc/systemd/journald.conf
echo "nf_conntrack" > /etc/modules-load.d/nf_conntrack.conf
echo "options nf_conntrack hashsize=65536"  >  /etc/modprobe.d/nf_conntrack.conf
curl https://raw.githubusercontent.com/Financial-Times/eks-files/master/files/91-nf_conntrack.conf > /etc/sysctl.d/91-nf_conntrack.conf
curl https://raw.githubusercontent.com/Financial-Times/eks-files/master/files/bootcommands.service > /etc/systemd/system/bootcommands.service
systemctl start authorized_keys.service
systemctl enable authorized_keys.service
systemctl start authorized_keys.timer
systemctl enable authorized_keys.timer
systemctl enable  bootcommand.service
systemctl start bootcommands.service

