#!/bin/bash

# Function to read email address from openpanel.config
read_email_address() {
    email=$(grep -E "^e-mail=" /etc/openpanel/openpanel/conf/openpanel.config | cut -d "=" -f2)
    echo "$email"
}

# Function to install CSF
install_csf() {
    wget https://download.configserver.com/csf.tgz
    tar -xzf csf.tgz
    rm csf.tgz
    cd csf
    sh install.sh
}

# Function to add csfpost.sh
add_csf_post() {
    cd ..
    rm -rf csf
    cp csfpost.sh /etc/csf/csfpost.sh
}


disable_docker_iptables() {
   echo -e '
   # Disable Docker iptables management
   # You need to manually edit the Docker daemon JSON to disable iptables management
   #
   # edit docker daemon json
   #
   # "iptables": false'
}

# Function to read UFW rules and add them to CSF
read_ufw_rules() {
    ufw status numbered | grep "\[ *[0-9]\+\]" | while read -r line; do
        rule=$(echo "$line" | awk '{print $2}')
        csf -a "$rule"
    done
}

# Function to disable CSF testing mode
edit_csf_conf() {
    sed -i 's/TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
    sed -i 's/ETH_DEVICE_SKIP = ""/ETH_DEVICE_SKIP = "docker0"/' /etc/csf/csf.conf
    sed -i 's/DOCKER = "0"/DOCKER = "1"/' /etc/csf/csf.conf
}

# Function to set email address for CSF alerts if not already set in openpanel.config
set_csf_email_address() {
    email_address=$(read_email_address)
    if [[ -n "$email_address" ]]; then
        sed -i "s/LF_ALERT_TO = \"\"/LF_ALERT_TO = \"$email_address\"/" /etc/csf/csf.conf
    fi
}

# Function to restart services
restart_services() {
    service ufw stop
    ufw disable
    service docker restart
    csf -r
}

# Function to copy files to OpenPanel
copy_files_to_openpanel() {
    cp csf.py /usr/local/admin/modules/settings/csf.py
    cp csf.html /usr/local/admin/templates/csf.html
    service admin restart
}

# Function to check CSF status
check_csf_status() {
    csf -s
}

# Main script execution


read_email_address
install_csf
disable_docker_iptables
add_csf_post
read_ufw_rules
edit_csf_conf
set_csf_email_address
restart_services
copy_files_to_openpanel
check_csf_status
