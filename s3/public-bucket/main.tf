resource "aws_s3_bucket" "project_bucket" {
  lifecycle {
    prevent_destroy = true
  }

  bucket = "notarize-${var.project}"

  acl = "public-read"
  policy = <<POLICY
{
    "Statement": [
        {
            "Action": [
                "s3:GetObject"
            ],
            "Effect": "Allow",
            "Principal": "*",
            "Resource": "arn:aws:s3:::notarize-${var.bucket}/*",
            "Sid": "PublicReadAccess"
        }
    ],
    "Version": "2012-10-17"
}
POLICY

  tags {
    project    = "${var.project}"
    gitrepo = "${var.gitrepo}"

    terrafrom = true
  }
}

