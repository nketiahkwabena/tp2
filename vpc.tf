resource "aws_vpc" "test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "test_vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "test_instance" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test_sub"
  }
}

resource "aws_subnet" "test_instance2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test_sub2"
  }
}

resource "aws_subnet" "test_instance3" {
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block        = "10.0.4.0/24"
  vpc_id            = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test_sub3"
  }
}

resource "aws_route_table_association" "nat_gateway" {
  subnet_id      = aws_subnet.test_instance2.id
  route_table_id = aws_route_table.nat_gateway.id
}

resource "aws_route_table_association" "nat_gateway1" {
  subnet_id      = aws_subnet.test_instance3.id
  route_table_id = aws_route_table.instance.id
}

resource "aws_instance" "test_ec2instance" {
  instance_type           = "t3.micro"
  ami                     = "ami-06b7bc20544bb2f42"
  subnet_id               = aws_subnet.test_instance2.id
  security_groups         = [aws_security_group.securitygroup.id]
  key_name                = aws_key_pair.ssh.key_name
  disable_api_termination = false
  ebs_optimized           = false
  root_block_device {
    volume_size = "8"
  }
  tags = {
    "Name" = "test_instance2"
  }
}

resource "aws_instance" "web_ec2instance" {
  instance_type           = "t3.micro"
  ami                     = "ami-06b7bc20544bb2f42"
  subnet_id               = aws_subnet.test_instance3.id
  security_groups         = [aws_security_group.securitygroup.id]
  key_name                = aws_key_pair.ssh.key_name
  disable_api_termination = false
  ebs_optimized           = false
  root_block_device {
    volume_size = "8"
  }
  tags = {
    "Name" = "test_instance3"
  }
}



resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "DummyMachine"
  public_key = tls_private_key.ssh.public_key_openssh
}

output "ssh_private_key_pem" {
  value = tls_private_key.ssh.public_key_pem
}

output "ssh_public_key_pem" {
  value = tls_private_key.ssh.public_key_pem
}

resource "aws_security_group" "securitygroup" {
  name        = "DummySecurityGroup"
  description = "DummySecurityGroup"
  vpc_id      = aws_vpc.test_vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    "Name" = "test_security_group"
  }
}

resource "aws_instance" "test_ec2instance3" {
  instance_type           = "t3.micro"
  ami                     = "ami-06b7bc20544bb2f42"
  subnet_id               = aws_subnet.test_instance.id
  security_groups         = [aws_security_group.securitygroup.id]
  key_name                = aws_key_pair.ssh.key_name
  disable_api_termination = false
  ebs_optimized           = false
  root_block_device {
    volume_size = "8"
  }
  tags = {
    "Name" = "test_instance1"
  }
}

output "instance_private_ip" {
  value = aws_instance.test_ec2instance.private_ip
}



resource "aws_subnet" "test_instance1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test_sub2"
  }
}

resource "aws_internet_gateway" "nat_gateway" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test_igw"
  }
}

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "app_gateway" {
  subnet_id      = aws_subnet.test_instance1.id
  route_table_id = aws_route_table.nat_gateway.id
}



resource "aws_eip" "nat_gateway" {

}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.test_instance1.id
  tags = {
    "Name" = "test_nat_gateway"
  }
}

output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}

resource "aws_route_table" "instance" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "instance" {
  subnet_id      = aws_subnet.test_instance.id
  route_table_id = aws_route_table.instance.id
}



resource "aws_instance" "ec2jumphost" {
  instance_type           = "t3.micro"
  ami                     = "ami-06b7bc20544bb2f42"
  subnet_id               = aws_subnet.test_instance1.id
  security_groups         = [aws_security_group.securitygroup.id]
  key_name                = aws_key_pair.ssh.key_name
  disable_api_termination = false
  ebs_optimized           = false
  root_block_device {
    volume_size = "10"
  }
  tags = {
    "Name" = "test_ec2_instance"
  }
}

resource "aws_eip" "jumphost" {
  instance = aws_instance.ec2jumphost.id


}

output "jumphost_ip" {
  value = aws_eip.jumphost.public_ip
}

