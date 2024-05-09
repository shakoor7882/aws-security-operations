output "vpc_id" {
  value = aws_vpc.main.id
}

output "az" {
  value = local.az
}

output "public_workload_subnet_id" {
  value = aws_subnet.public.id
}

output "private_workload_subnet_id" {
  value = aws_subnet.private.id
}

output "vpce_workload_subnet_id" {
  value = aws_subnet.vpce.id
}
