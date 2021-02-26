terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = format("%s VPC", var.prefix)
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s IGW", var.prefix)
  }
}

resource "aws_eip" "a" {
  vpc = true
  tags = {
    Name = format("%s EIP 1", var.prefix)
  }
}

resource "aws_eip" "b" {
  vpc = true
  tags = {
    Name = format("%s EIP 2", var.prefix)
  }
}

resource "aws_subnet" "internal_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_internal_1_cidr
  availability_zone = var.subnet_az_primary
  tags = {
    Name = format("%s Internal Subnet 1", var.prefix)
  }
}

resource "aws_subnet" "internal_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_internal_2_cidr
  availability_zone = var.subnet_az_secondary
  tags = {
    Name = format("%s Internal Subnet 2", var.prefix)
  }
}

resource "aws_subnet" "external_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_external_1_cidr
  availability_zone = var.subnet_az_primary
  tags = {
    Name = format("%s External Subnet 1", var.prefix)
  }
}

resource "aws_subnet" "external_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_external_2_cidr
  availability_zone = var.subnet_az_secondary
  tags = {
    Name = format("%s External Subnet 2", var.prefix)
  }
}

resource "aws_nat_gateway" "a" {
  allocation_id = aws_eip.a.id
  subnet_id     = aws_subnet.external_1.id
  tags = {
    Name = format("%s NAT Gateway 1", var.prefix)
  }
}

resource "aws_nat_gateway" "b" {
  allocation_id = aws_eip.b.id
  subnet_id     = aws_subnet.external_2.id
  tags = {
    Name = format("%s NAT Gateway 2", var.prefix)
  }
}

# TODO NACL streamlining
resource "aws_network_acl" "external" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.external_1.id, aws_subnet.external_2.id]
  ingress {
    protocol   = "tcp"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "443"
    to_port    = "443"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = "200"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "80"
    to_port    = "80"
  }

  # TODO restrict this!
  ingress {
    protocol   = "tcp"
    rule_no    = "300"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "22"
    to_port    = "22"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = "400"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "1024"
    to_port    = "65535"
  }

  tags = {
    Name = format("%s External NACL", var.prefix)
  }
}

resource "aws_network_acl" "internal" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.internal_1.id, aws_subnet.internal_2.id]
  ingress {
    protocol   = "tcp"
    rule_no    = "100"
    action     = "allow"
    # TODO more elegant subnet calculation
    cidr_block = var.vpc_cidr
    from_port  = "1024"
    to_port    = "65535"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = "200"
    action     = "allow"
    # TODO more elegant subnet calculation
    cidr_block = var.vpc_cidr
    from_port  = "22"
    to_port    = "22"
  }

  tags = {
    Name = format("%s Internal NACL", var.prefix)
  }
}

resource "aws_route_table" "external" {
  vpc_id     = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = format("%s External Subnets Route Table", var.prefix)
  }
}

resource "aws_route_table_association" "external" {
    subnet_id = aws_subnet.external_1.id
    route_table_id = aws_route_table.external.id
}

resource "aws_route_table" "internal_1" {
  vpc_id     = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a.id
  }
  tags = {
    Name = format("%s Internal Subnet 1 Route Table", var.prefix)
  }
}

resource "aws_route_table" "internal_2" {
  vpc_id     = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.b.id
  }
  tags = {
    Name = format("%s Internal Subnet 2 Route Table", var.prefix)
  }
}

resource "aws_route_table_association" "internal_1" {
    subnet_id = aws_subnet.internal_1.id
    route_table_id = aws_route_table.internal_1.id
}

resource "aws_route_table_association" "internal_2" {
    subnet_id = aws_subnet.internal_2.id
    route_table_id = aws_route_table.internal_2.id
}
