# Terraform config for Bastion Host provisioning
resource "aws_instance" "bastion" {
  ami           = "ami-xxxxxxx" # Replace with your region's bastion AMI
  instance_type = "t3.micro"
  subnet_id     = "${var.dmz_subnet_id}"
  key_name      = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${var.bastion_sg_id}"]
  tags = {
    Name = "okd-bastion"
  }
}

# Outputs for bastion host connection
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
