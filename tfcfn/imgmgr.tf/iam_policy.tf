resource "aws_iam_role" "img_mgr_role" {
  name                = "img_mgr_role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "img_mgr_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Effect   = "Allow"
          Resource = "${aws_s3_bucket.img_mgr_bucket.arn}/*"
        },
        {
          Action   = ["s3:ListBucket"]
          Effect   = "Allow"
          Resource = aws_s3_bucket.img_mgr_bucket.arn
        },
        {
          Action   = ["ec2:DescribeTags"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Environment = var.environment
    Namespace   = var.namespace
  }
}

#reate instance profile
resource "aws_iam_instance_profile" "img_mgr_profile" {
  name = "img_mgr_profile"
  role = aws_iam_role.img_mgr_role.name
}
