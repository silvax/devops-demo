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
echo "source_repo=$GIT_URL" >> /home/ec2-user/ami_info.txt
echo "commit_hash=$GIT_COMMIT" >> /home/ec2-user/ami_info.txt
echo "build=$JOB_NAME" >> /home/ec2-user/ami_info.txt
echo "build_number=$BUILD_NUMBER" >> /home/ec2-user/ami_info.txt
echo "build_url=$BUILD_URL" >> /home/ec2-user/ami_info.txt
