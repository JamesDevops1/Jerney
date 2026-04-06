provider "aws" {
  region = "us-east-1"
}

# Generate private key locally
resource "tls_private_key" "jereny_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS key pair using generated public key
resource "aws_key_pair" "jereny_key" {
  key_name   = "jereny-key"
  public_key = tls_private_key.jereny_key.public_key_openssh
}

# Save private key to a file
resource "local_file" "jereny_private_key" {
  content  = tls_private_key.jereny_key.private_key_pem
  filename = "jereny-key.pem"
  file_permission = "0400"
}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group
resource "aws_security_group" "jereny_sg" {
  name = "jereny-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

# EC2 Instance
resource "aws_instance" "jereny_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.jereny_key.key_name

  security_groups = [aws_security_group.jereny_sg.name]

  tags = {
    Name = "jereny-server"
  }
}

# Output public IP
output "public_ip" {
  value = aws_instance.jereny_server.public_ip
}