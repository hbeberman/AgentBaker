#!/bin/bash

set -e

# Disable waagent autoupdate
echo AutoUpdate.Enabled=n >> /etc/waagent.conf

# Disable default eth0 dhcp rule
truncate -s 0 /etc/systemd/network/99-dhcp-en.network

# Create empty dir for compatibility with dir or create containers trying to mount from host like managed prometheus
mkdir -p /usr/local/share/ca-certificates/

# Setup a symlink for lg-redirect-sysext
mkdir -p /etc/extensions/lg-redirect-sysext/usr/local/
mkdir -p /opt/bin
ln -s /opt/bin /etc/extensions/lg-redirect-sysext/usr/local/bin

# Place ci-syslog.watcher.sh into the /usr/local/bin overlay
mv /opt/scripts/ci-syslog-watcher.sh /usr/local/bin/ci-syslog-watcher.sh

# Create release-notes.txt
mkdir -p /_imageconfigs/out
echo "release notes stub" >> /_imageconfigs/out/release-notes.txt
