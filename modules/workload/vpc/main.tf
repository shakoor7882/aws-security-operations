locals {
  az = "${var.region}a"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.workload}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ig-${var.workload}"
  }
}

### NAT Gateway ###
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat-${var.workload}"
  }
}

### Route Tables ###
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-${var.workload}-workload-pub"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "rt-${var.workload}-workload-pri"
  }
}

resource "aws_route_table" "vpce" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-workload-vpce"
  }
}

resource "aws_route_table" "secops" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "rt-${var.workload}-secops"
  }
}

### Subnets ###
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-workload-pub"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.50.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-workload-pri"
  }
}

resource "aws_subnet" "vpce" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.200.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-workload-vpce"
  }
}

resource "aws_subnet" "secops" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.80.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-secops"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "vpce" {
  subnet_id      = aws_subnet.vpce.id
  route_table_id = aws_route_table.vpce.id
}

resource "aws_route_table_association" "secops" {
  subnet_id      = aws_subnet.secops.id
  route_table_id = aws_route_table.secops.id
}

# Clear all default entries (CKV2_AWS_12)
resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.main.default_route_table_id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# resource "aws_default_network_acl" "default" {
#   default_network_acl_id = aws_vpc.main.default_network_acl_id
# }
