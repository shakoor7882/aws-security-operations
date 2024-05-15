output "vulnerapp_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "cryptominer_repository_url" {
  value = aws_ecr_repository.cryptominer.repository_url
}
