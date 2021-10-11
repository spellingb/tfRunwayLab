

output "ami_id" {
  value = data.aws_ami.ami.id
}
output "imgmgr_bucket" {
  value = aws_s3_bucket.img_mgr_bucket.bucket
}
/*
output "userdata" {
  value = "${local.userdata}"
}
*/
output "KeyPair" {
  value = var.keypair
}
output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}
output "public_subnet_list" {
  value = data.terraform_remote_state.vpc.outputs.public_subnet_list
}
output "private_subnet_list" {
  value = data.terraform_remote_state.vpc.outputs.private_subnet_list
}
output "lb_endpoint" {
  value = aws_lb.img_mgr_lb.dns_name
}