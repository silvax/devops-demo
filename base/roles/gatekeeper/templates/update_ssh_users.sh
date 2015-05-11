#!/usr/bin/env bash


# Lets run ssh_dynamodb.py to pull the latest data
/opt/gatekeeper/ssh_dynamodb.py -t ssh_users -r {{ ansible_ec2_placement_region }} -f /opt/gatekeeper/users.yml

# now lets run the Ansible playbook
ansible-playbook -i /home/ec2-user/base/inv /opt/gatekeeper/ssh_create_users.yml
