output "public_ip" {
  value = [for instance in aws_instance.ansible : instance.public_ip if instance.tags["Name"] != "ansible_server-1"]
}