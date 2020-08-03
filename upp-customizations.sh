#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

echo "Customize /etc/docker/daemon.json"
sed -i "/max-size/d" /etc/docker/daemon.json
sed -i "/max-file/d" /etc/docker/daemon.json
sed -i "s/json-file/journald/g" /etc/docker/daemon.json

systemctl restart docker.service

echo "Add authorized keys setup"
cat > /etc/systemd/system/authorized_keys.service << EOF
[Unit]
Description=Update authorized_keys
[Service]
Type=oneshot
ExecStartPre=/bin/sh -c 'mkdir -p /home/ec2-user/.ssh && touch /home/ec2-user/.ssh/authorized_keys'
ExecStart=/bin/sh -c 'curl -sSL --retry 5 --retry-delay 2 -o /tmp/authorized_keys.sha512 https://raw.githubusercontent.com/Financial-Times/up-ssh-keys/master/authorized_keys.sha512'
ExecStart=/bin/sh -c 'curl -sSL --retry 5 --retry-delay 2 -o /tmp/authorized_keys https://raw.githubusercontent.com/Financial-Times/up-ssh-keys/master/authorized_keys'
ExecStart=/bin/sh -c 'cd /tmp/ && sha512sum -c authorized_keys.sha512 && cp authorized_keys /home/ec2-user/.ssh/authorized_keys && chmod 700 /home/ec2-user/.ssh && chmod 600 /home/ec2-user/.ssh/authorized_keys && chown -R ec2-user:ec2-user /home/ec2-user/.ssh'
Restart=no
EOF

systemctl start authorized_keys.service
systemctl enable authorized_keys.service

cat > /etc/systemd/system/authorized_keys.timer << EOF
[Unit]
Description=Authorized keys timer
[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
[Install]
WantedBy=timers.target
EOF

systemctl start authorized_keys.timer
systemctl enable authorized_keys.timer

echo "Customize journald configuration"
cat > /etc/systemd/journald.conf << EOF
[Journal]
MaxLevelConsole=crit
Compress=false
RateLimitInterval=0
RateLimitBurst=0
SystemMaxUse=4G
RuntimeMaxUse=4G
EOF

cp /usr/lib/systemd/system/systemd-journald.service /systemd-journald.service.org.bkp
cat > /usr/lib/systemd/system/systemd-journald.service << EOF
[Unit]
Description=Journal Service
Documentation=man:systemd-journald.service(8) man:journald.conf(5)
DefaultDependencies=no
Requires=systemd-journald.socket
After=systemd-journald.socket syslog.socket
Before=sysinit.target

[Service]
Type=notify
Sockets=systemd-journald.socket
CapabilityBoundingSet=CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_SYS_PTRACE CAP_SYSLOG CAP_AUDIT_CONTROL CAP_AUDIT_READ CAP_CHOWN CAP_DAC_READ_SEARCH CAP_FOWNER CAP_SETUID CAP_SETGID CAP_MAC_OVERRIDE
ExecStart=/usr/lib/systemd/systemd-journald
Restart=always
RestartSec=0
StandardOutput=null
FileDescriptorStoreMax=4224
NoNewPrivileges=yes
RestrictAddressFamilies=AF_UNIX AF_NETLINK
SystemCallArchitectures=native
SystemCallErrorNumber=EPERM
SystemCallFilter=@system-service
WatchdogSec=3min
LimitNOFILE=524288
EOF

systemctl daemon-reload
systemctl restart systemd-journald

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
