#!/bin/bash

# this file is used in the asgard plugin to customize the user-data on instances launch configuration.

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Creating environment tag for instance"
aws ec2 create-tags --tags Key='environment',Value='dev' --resources `curl http://169.254.169.254/latest/meta-data/instance-id/` --region us-east-1
echo

echo "Checking if the script to tag instance is present"
if [ -f /opt/taginstance.sh ]
  then
  echo "Found tag instance script, running it..."
  /opt/taginstance.sh >>/opt/taginstance.log
fi

echo "Checking if the base/configure playbook exists"
if [ -f /home/ec2-user/base/configure.yml ]
  then
    echo "/base/configure playbook found running base configuration.."
    ansible-playbook -i /home/ec2-user/base/inv /home/ec2-user/base/configure.yml
fi
echo
echo "...done."

echo
echo "running configure playbook for the service"
ansible-playbook  --i /home/ec2-user/ansible/ininservice/inv /home/ec2-user/ansible/ininservice/configure.yml
