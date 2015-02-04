#!/bin/bash
sudo yum install python-pip -y
sudo pip install ansible==1.7.1
sudo mkdir -p /etc/ansible
sudo chown ec2-user:ec2-user /etc/ansible
sudo mv /home/ec2-user/base/ansible.cfg /etc/ansible/ansible.cfg
sudo chown ec2-user:ec2-user /etc/ansible/ansible.cfg
sudo touch /home/ec2-user/ansible.log
sudo chown ec2-user:ec2-user /home/ec2-user/ansible.log
sudo chmod 666 /home/ec2-user/ansible.log
sudo mkdir -p /var/inin
sudo echo "source_repo=$GIT_URL" >> /var/inin/base_ami_info.txt
sudo echo "commit_hash=$GIT_COMMIT" >> /var/inin/base_ami_info.txt
sudo echo "build=$JOB_NAME" >> /var/inin/base_ami_info.txt
sudo echo "build_number=$BUILD_NUMBER" >> /var/inin/base_ami_info.txt
sudo echo "build_url=$BUILD_URL" >> /var/inin/base_ami_info.txt
