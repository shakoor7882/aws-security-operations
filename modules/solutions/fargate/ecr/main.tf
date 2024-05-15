resource "aws_ecr_repository" "main" {
  name                 = "ecr-vulnerapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# resource "aws_ecr_pull_through_cache_rule" "example" {
#   ecr_repository_prefix = "ecr-public"
#   upstream_registry_url = "registry-1.docker.io"
# }
