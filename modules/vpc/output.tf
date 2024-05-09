output "vpc_id" {
  value = aws_vpc.main.id
}

output "azs" {
  value = [local.az1, local.az2]
}

output "subnets" {
  value = [aws_subnet.public1.id, aws_subnet.public2.id]
}
