#!/bin/bash

set -e

# CNI download dir
mkdir -p /opt/cni/downloads

# Disable waagent autoupdate
echo AutoUpdate.Enabled=n >> /etc/waagent.conf

# Disable default eth0 dhcp rule
truncate -s 0 /etc/systemd/network/99-dhcp-en.network

# Fix WAAgent SSH dir
sed -i "s|OS.SshDir=.*$|OS\.SshDir=/etc/ssh|" /etc/waagent.conf

# Create empty dir for compatibility with dir or create containers trying to mount from host like managed prometheus
mkdir -p /usr/local/share/ca-certificates/

# Make sure that data disk gets mounted into /mnt
echo "/dev/disk/cloud/azure_resource-part1    /mnt    auto    defaults,nofail,x-systemd.after=cloud-init.service,_netdev,comment=cloudconfig  0       2" >> /etc/fstab

# Ensure there's a directory for tardev snapshotter signatures
mkdir -p /var/lib/containerd/io.containerd.snapshotter.v1.tardev/signatures

# Increase logging verbosity for tardev snapshotter
sed -i 's/RUST_LOG=tardev_snapshotter=info/RUST_LOG=tardev_snapshotter=trace/g' /usr/lib/systemd/system/tardev-snapshotter.service

# Postinstall oras until Prism fix for .repo files with URLS is published
# https://github.com/microsoft/azure-linux-image-tools/pull/242
tdnf install -y oras