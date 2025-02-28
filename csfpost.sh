#!/bin/bash

# Get all bridge network names from Docker
docker_bridge_ids=$(/usr/bin/docker network ls --filter driver=bridge --format "{{.ID}}")

output_header='''

echo "[DOCKER] Setting up FW rules."

# Check if the DOCKER chain exists, flush it if it does, otherwise create it
if /usr/sbin/iptables -L DOCKER &> /dev/null; then
    echo "[DOCKER] Flushing existing DOCKER chain."
    /usr/sbin/iptables -F DOCKER
else
    echo "[DOCKER] Creating DOCKER chain."
    /usr/sbin/iptables -N DOCKER
fi
'''

output_footer='''

echo "[DOCKER] Done running csfpost.sh."
'''

output_body=""

# Template segment for each bridge-subnet pair
template_segment='
# Masquerade outbound connections from containers
echo "Adding MASQUERADE rule for {subnet} on {bridge}"
/usr/sbin/iptables -t nat -A POSTROUTING -s {subnet} ! -o {bridge} -j MASQUERADE

# Accept established connections to the docker containers
echo "Adding FORWARD rule to accept established connections for {bridge}"
/usr/sbin/iptables -t filter -A FORWARD -o {bridge} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT

# Allow docker containers to communicate with themselves & outside world
echo "Adding FORWARD rule to allow communication for {bridge}"
/usr/sbin/iptables -t filter -A FORWARD -i {bridge} ! -o {bridge} -j ACCEPT
/usr/sbin/iptables -t filter -A FORWARD -i {bridge} -o {bridge} -j ACCEPT
'

# Loop through each network ID and inspect it
for id in $docker_bridge_ids; do
    # Extract the bridge name (network interface) using docker network inspect
    bridge_name=$(/usr/bin/docker network inspect $id --format '{{ index .Options "com.docker.network.bridge.name" }}')
    # Check if the bridge name is not empty
    if [ -n "$bridge_name" ]; then
        bridge_name="$bridge_name"
    else
        # Fallback to default bridge naming convention if custom name isn't set
        bridge_name="br-$id"
    fi
    subnet=$(/usr/bin/docker network inspect $id --format '{{(index .IPAM.Config 0).Subnet}}')

    # Substitute the bridge and subnet into the template segment
    if [ -n "$subnet" ]; then
        output_body+="$(echo "$template_segment" | sed "s|{subnet}|$subnet|g" | sed "s|{bridge}|$bridge_name|g")"
    fi
done

# Combine header, dynamic body, and footer
output="$output_header$output_body$output_footer"


#fallback..
echo "Restarting Docker.."
service docker restart

# Write the output to csfpost.sh
eval "$output"
