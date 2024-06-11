#!/bin/bash

# Get all bridge network names from Docker
docker_bridge_ids=$(docker network ls --filter driver=bridge --format "{{.ID}}")

output_header='''

echo "[DOCKER] Setting up FW rules."

iptables -N DOCKER
'''

output_footer='''

echo "[DOCKER] Done running csfpost.sh."
'''

output_body=""

# Template segment for each bridge-subnet pair
template_segment='''
# Masquerade outbound connections from containers
iptables -t nat -A POSTROUTING -s {subnet} ! -o {bridge} -j MASQUERADE

# Accept established connections to the docker containers
iptables -t filter -A 
