output "Region" {
  value = var.region
}
output "Environment" {
  value = var.environment
}
output "Ciderblock" {
  value = "${lookup(var.CiderBlock, var.region)}.0.0/16"
}
output "availability_zones" {
  value = data.aws_availability_zones.availability_zones
}
output "pub_networks" {
  value = local.pub_networks
}
output "priv_networks" {
  value = local.priv_networks
}
output "VPC_Name" {
  value = "${var.customer}-${var.environment}-VPC"
}
output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnet_list" {
  value = module.vpc.public_subnets
}
output "private_subnet_list" {
  value = module.vpc.private_subnets
}