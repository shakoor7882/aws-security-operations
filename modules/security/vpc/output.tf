output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "vpce_subnet_id" {
  value = aws_subnet.vpce.id
}

output "cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}
