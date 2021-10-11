# call the vpc module outputs
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.statebucket
    region = var.region
    key    = "env:/common/VPC"
  }
}

# retrieve our AMI ID
data "aws_ami" "ami" {
  most_recent = true
  #name_regex  = var.os == "windows" ? "^Windows_Server-2019-English-Full-Base-*" : "Amazon Linux 2 AMI 2.0.*HVM gp2"
  owners = ["amazon"]
  #owner_id    = var.os == "windows" ? "801119661308" : "137112412989"
  filter {
    name   = "name"
    values = var.os == "windows" ? ["Windows_Server-2019-English-Full-Base*"] : ["amzn2-ami-hvm*"]
  }
}
