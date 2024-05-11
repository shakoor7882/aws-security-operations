output "arn" {
  value = aws_instance.main.arn
}

output "private_dns" {
  value = aws_instance.main.private_dns
}

output "instance_id" {
  value = aws_instance.main.id
}
