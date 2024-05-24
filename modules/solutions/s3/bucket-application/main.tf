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
