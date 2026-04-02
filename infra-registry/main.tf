## Infrastructure de l'EC2 Registry (Docker Private Registry)
## Provisionnée une seule fois, configurée via config/deploy.yml

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
  region = "eu-west-3"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "tls_private_key" "registry_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "registry_key" {
  key_name   = "registry-key-terraform"
  public_key = tls_private_key.registry_pk.public_key_openssh
}

resource "local_file" "registry_ssh_key" {
  filename        = "${path.module}/registry-key-terraform.pem"
  content         = tls_private_key.registry_pk.private_key_pem
  file_permission = "0400"
}

resource "aws_security_group" "registry_sg" {
  name        = "registry-sg"
  description = "Allow SSH, HTTP (UI), HTTPS (registry)"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP - Registry UI"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS - Docker Registry"
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "registry_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.registry_key.key_name

  vpc_security_group_ids = [aws_security_group.registry_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Registry-Server"
  }
}

output "registry_ip" {
  value = aws_instance.registry_server.public_ip
}

output "registry_private_key_pem" {
  value     = tls_private_key.registry_pk.private_key_pem
  sensitive = true
}
