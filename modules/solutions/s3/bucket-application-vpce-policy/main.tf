resource "aws_s3_bucket_policy" "allow_access_only_from_vpce" {
  bucket = var.bucket_id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "Policy1415115909152",
    "Statement" : [
      {
        "Sid" : "Access-to-specific-VPCE-only",
        "Principal" : "*",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ],
        "Condition" : {
          "StringNotEquals" : {
            "aws:SourceVpce" : "${var.vpce_id}"
          }
        }
      },
      {
        "Sid" : "Access-to-specific-VPCE-only",
        "Principal" : "*",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ],
        "Condition" : {
          "NotIpAddress" : {
            "aws:SourceIp" : [
              "192.0.2.0/24",
            ]
          }
        }
      }
    ]
  })
}
