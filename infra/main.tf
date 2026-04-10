terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region = "eu-west-3" #Paris
}

# 1. AMI Ubuntu 24.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 2. Création de la clé SSH (générée à la volée, jamais stockée dans le repo)
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "app-key-terraform"
  public_key = tls_private_key.pk.public_key_openssh
}

# Sauvegarde de la clé privée locale pour tester Ansible en local
resource "local_file" "ssh_key" {
  filename        = "${path.module}/app-key-terraform.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# 3. Security Group
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH, Frontend (3000), API (8000)"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "API"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Instance EC2
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "App-Server"
  }
}

# 5. Outputs pour la CI (IP publique + clé privée pour Ansible)
output "instance_ip" {
  value     = aws_instance.app_server.public_ip
  sensitive = true
}

output "private_key_pem" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}
