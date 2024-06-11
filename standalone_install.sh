#!/bin/bash

# Install CSF
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
rm csf.tgz
cd csf
sh install.sh

# Add csfpost.sh
cd ..
rm -rf csf
cp csfpost.sh /etc/csf/csfpost.sh

# Disable Docker iptables management
# You need to manually edit the Docker daemon JSON to disable iptables management
#
# edit docker daemon json
#
# "iptables": false


# Read UFW rules and add them to CSF
ufw status numbered | grep "\[ *[0-9]\+\]" | while read -r line; do
    rule=$(echo "$line" | awk '{print $2}')
    csf -a "$rule"
done


# Disable CSF testing mode
sed -i 's/TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf


# Restart services
service ufw stop
service ufw disable
service docker restart
csf -r

# Copy files to OpenPanel
cp csf.py /usr/local/admin/modules/settings/csf.py
cp csf.html /usr/local/admin/templates/csf.html
service admin restart


# Check status

