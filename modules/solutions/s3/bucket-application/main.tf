resource "random_string" "bucket" {
  length    = 10
  min_lower = 10
  special   = false
}

resource "aws_s3_bucket" "main" {
  bucket = "bucket-${var.workload}-${random_string.bucket.result}"

  # For development purposes
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "main" {
#   bucket = aws_s3_bucket.main.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_public_access_block" "main" {
#   bucket = aws_s3_bucket.main.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "main" {
#   bucket = aws_s3_bucket.main.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_logging" "main" {
#   bucket = aws_s3_bucket.main.id

#   target_bucket = aws_s3_bucket.main.id
#   target_prefix = "log/"
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
#   bucket = aws_s3_bucket.main.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = var.kms_key_arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }
