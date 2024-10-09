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
### fs.file-max
###
### Setting Kernel Parameters Persistently on the node

cat >> /etc/sysctl.d/01-custom.conf << EOF
fs.file-max=1586826
EOF

### Set parameters immediately
sysctl -p /etc/sysctl.d/01-custom.conf

### To verify that the parameters are set use the below commands:
### sysctl fs.file-max
