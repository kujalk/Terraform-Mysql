/*
Generate Keypair dynamically store it in the file
Create EC2 instance with the Key pair generate
Install Mysql
Add secuiry Groups

Developer - K.Janarthanan
*/

resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 2048

  provisioner "local-exec" {
    command     = <<EOT
    '${tls_private_key.ssh-key.private_key_pem}' | % {$_ -replace "`r", ""} | Set-Content -NoNewline ./'${var.keyname}.pem' -Force
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    command     = "Remove-Item *.pem -Force"
    interpreter = ["PowerShell", "-Command"]
    when        = destroy
  }
}

resource "aws_key_pair" "generated-key" {
  key_name   = var.keyname
  public_key = tls_private_key.ssh-key.public_key_openssh
}

resource "aws_instance" "Server" {
  ami                    = var.amiid
  instance_type          = var.ec2type
  key_name               = aws_key_pair.generated-key.key_name
  user_data_base64       = base64encode(local.mysql_install)
  vpc_security_group_ids = [aws_security_group.Mysql-SG.id]

  tags = {
    Name = var.ec2name
  }
}

resource "aws_security_group" "Mysql-SG" {
  name        = "Mysql-SG"
  description = "Mysql Backend"

  tags = {
    Name = "MySql Security Group"
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outside"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}