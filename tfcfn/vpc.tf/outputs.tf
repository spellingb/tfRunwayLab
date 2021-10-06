output "Region" {
  value = var.region
}
output "Environment" {
  value = var.environment
}
output "Ciderblock" {
  value = "${lookup(var.CiderBlock, var.region)}.0.0/16"
}
output "AZs" {
  value = data.aws_availability_zones.AZs.names
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