#!/bin/bash
sudo yum update -y
sudo -i

useradd -m -d /home/ansadmin -c "Ansible user controller" ansadmin
echo "test123" | passwd --stdin ansadmin
sed -i '110a\ansadmin ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

sudo yum install python3 -y

sudo sed -i '61s/#//; 63s/^/#/' /etc/ssh/sshd_config
sudo systemctl reload sshd

sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker 
# add user to docker group 
sudo usermod -aG docker ansadmin

sudo mkdir /opt/docker
sudo chown -R ansadmin: /opt/docker