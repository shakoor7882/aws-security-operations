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
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "nat-${var.workload}"
  }
}

### Route Tables ###
resource "aws_route_table" "public1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-pub1"
  }
}

resource "aws_route_table" "public2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-pub2"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-pri"
  }
}

resource "aws_route_table" "vpce" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-vpce"
  }
}

# Using the same NAT Gateway for both subnets, for development only
resource "aws_route" "public_subnet1_to_gateway" {
  route_table_id         = aws_route_table.public1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "public_subnet2_to_gateway" {
  route_table_id         = aws_route_table.public2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "private_subnet_to_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

### Subnets ###
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-pub1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-pub2"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-pri"
  }
}

resource "aws_subnet" "vpce" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-${var.workload}-vpce"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public1.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public2.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "vpce" {
  subnet_id      = aws_subnet.vpce.id
  route_table_id = aws_route_table.vpce.id
}

# Clear all default entries (CKV2_AWS_12)
resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.main.default_route_table_id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}
