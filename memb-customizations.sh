#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'


### Install crictl tool
VERSION="v1.25.0"
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz


echo "Customize the node kernel parameters"
### The kernel parameter customization here is sometimes being overriten by the
### kube-proxy daemonset. The this is because the kernel parameters are not
### namespaces and impact the whole node. The kube-proxy configuration is also
### enforced to set the same values. The parameters are:
### nf_conntrack hashsize
### net.netfilter.nf_conntrack_tcp_timeout_established
### net.netfilter.nf_conntrack_max
###
### Setting Kernel Parameters Persistently on the node
cat > /etc/modprobe.d/nf_conntrack.conf << EOF
options nf_conntrack hashsize=65536
EOF

cat >> /etc/sysctl.d/01-custom.conf << EOF
net.netfilter.nf_conntrack_tcp_timeout_established=300
net.netfilter.nf_conntrack_max=262144
fs.file-max=1586826
EOF

### Set parameters immediately
modprobe nf_conntrack hashsize=65536
sysctl -p /etc/sysctl.d/01-custom.conf

### To verify that the parameters are set use the below commands:
### sysctl net.netfilter.nf_conntrack_tcp_timeout_established
### sysctl net.netfilter.nf_conntrack_max
### sysctl fs.file-max
### cat /sys/module/nf_conntrack/parameters/hashsize
