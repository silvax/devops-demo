#!/usr/bin/env bash

# Lets run ssh_dynamodb.py to pull the latest data
{% if allTags.tags.environment in ["dev", "test", "stage"] %}
/opt/gatekeeper/ssh_dynamodb.py -t ssh-user -r {{ ansible_ec2_placement_region }} -f /opt/gatekeeper/users.yml -s {{ gatekeeper_arn }}
{% else %}
/opt/gatekeeper/ssh_dynamodb.py -t ssh-user -r {{ ansible_ec2_placement_region }} -f /opt/gatekeeper/users.yml
{% endif %}

# now lets run the Ansible playbook
ansible-playbook -i /home/ec2-user/base/inv /opt/gatekeeper/ssh_create_users.yml
