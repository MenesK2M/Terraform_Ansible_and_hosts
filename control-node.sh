#!/bin/bash
sudo yum install python3-pip -y

sudo amazon-linux-extras install ansible2 -y

sudo sed -i '10a\deprecation_warnings = false' /etc/ansible/ansible.cfg

sudo rm -rf /etc/ansible/hosts
