terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#Configure the aws provider
provider "aws" {
  region     = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

#creae security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on port 22"

  #allow access on port 22
  ingress {
    description = 22
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Monitoring Server security group"
  }
}

resource "aws_instance" "Monitoring_server" {
  ami             = "ami-02d26659fd82cf299"
  instance_type   = "t2.medium"
  security_groups = [aws_security_group.ec2_security_group.name]
  key_name        = var.key_name

  tags = {
    Name = var.instance_name
  }
}