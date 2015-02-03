#!/bin/bash
sudo yum install python-pip -y
sudo pip install ansible==1.7.1
sudo mkdir -p /etc/ansible
sudo mv /home/ec2-user/base/ansible.cfg /etc/ansible/ansible.cfg
sudo touch /home/ec2-user/ansible.log
sudo chown ec2-user:ec2-user /home/ec2-user/ansible.log
sudo chmod 666 /home/ec2-user/ansible.log
