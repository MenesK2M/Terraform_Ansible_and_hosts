resource "aws_instance" "ansible" {
  ami           = data.aws_ami.amz-ami-ansible.id
  instance_type = var.instance_type
  key_name      = var.key_name_linux
  count         = 3
  tags = {
    "Name" = "ansible_server-${count.index + 1}"
  }
  availability_zone = var.aws_availability_zone
  security_groups   = var.security_groups_linux
  user_data         = file("${path.module}/ansible.sh")


}

resource "local_file" "hosts" {
  filename = "${abspath(path.root)}/hosts"
  content  = join("\n", [for instance in aws_instance.ansible : instance.public_ip if instance.tags["Name"] != "ansible_server-1"])
}

resource "null_resource" "control" {
  depends_on = [local_file.hosts]
  triggers = {
    change = timestamp()
  }

  connection {
    agent       = false
    type        = "ssh"
    user        = "ec2-user"
    password    = ""
    host        = element(aws_instance.ansible.*.public_ip, 0)
    private_key = file("${path.module}/key.pem")
  }

  provisioner "file" {
    source = "id_rsa"
    destination = "/home/ec2-user/id_rsa"
  }

  provisioner "file" {
    source = "id_rsa.pub"
    destination = "/home/ec2-user/id_rsa.pub"
  }

  provisioner "file" {
    source = "control-node.sh"
    destination = "/home/ec2-user/control-node.sh"
  }

  provisioner "file" {
    source = "hosts"
    destination = "/home/ec2-user/hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      "sudo hostnamectl set-hostname master",
      "sleep 60",
      "chmod 700 /home/ec2-user/control-node.sh",
      "bash -x /home/ec2-user/control-node.sh",
      "sudo mv /home/ec2-user/hosts /etc/ansible/",
      "sudo chown -R root: /etc/ansible/hosts",
      "sudo mkdir /home/ansadmin/.ssh",
      "sudo mv /home/ec2-user/id_rsa /home/ansadmin/.ssh/",
      "sudo mv /home/ec2-user/id_rsa.pub /home/ansadmin/.ssh/",
      "sudo chown -R ansadmin: /home/ansadmin/.ssh",
      "sudo chmod 700 /home/ansadmin/.ssh/",
      "sudo chmod 600 /home/ansadmin/.ssh/id_rsa",
      "sudo sed -i '72s/#//' /etc/ansible/ansible.cfg"
    ]
    on_failure = continue
  }

}

resource "null_resource" "slave" {
  depends_on = [aws_instance.ansible]
  triggers = {
    change = timestamp()
  }
  count = length(aws_instance.ansible) > 1 ? length(aws_instance.ansible) - 1 : 0

  connection {
    agent       = false
    type        = "ssh"
    user        = "ec2-user"
    password    = ""
    host        = element(aws_instance.ansible.*.public_ip, count.index + 1)
    private_key = file("${path.module}/key.pem")
  }

  provisioner "file" {
    source = "id_rsa.pub"
    destination = "/home/ec2-user/id_rsa.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname slave",
      "sleep 60",
      "sudo mkdir /home/ansadmin/.ssh/",
      "sudo mv /home/ec2-user/id_rsa.pub /home/ansadmin/.ssh/authorized_keys",
      "sudo chmod 600 /home/ansadmin/.ssh/authorized_keys",
      "sudo chown -R ansadmin:ansadmin /home/ansadmin/.ssh/"
    ]
    on_failure = continue
  }

}