#!/usr/bin/env bash


# Lets run ssh_dynamodb.py to pull the latest data
/opt/keymaster/ssh_dynamodb.py 

# now lets run the Ansible playbook
ansible-playbook -i /home/ec2-user/base/inv /opt/keymaster/ssh_create_users.yml
