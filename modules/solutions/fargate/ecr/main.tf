resource "aws_ecr_repository" "main" {
  name                 = "ecr-vulnerapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "cryptominer" {
  name                 = "ecr-cryptominer"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
