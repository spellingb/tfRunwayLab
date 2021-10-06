module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  name                = "${var.customer}-${var.environment}-VPC"
  cidr                = "${lookup(var.CiderBlock, var.region)}.0.0/16"
  azs                 = local.AZs
  private_subnets     = local.priv_networks
  public_subnets      = local.pub_networks
  enable_nat_gateway  = true

  public_subnet_tags  = {
    Name = "${var.namespace}-Public"
    Environment = var.environment
  }
  private_subnet_tags = {
    Name = "${var.namespace}-Private"
    Environment = var.environment
  }
  tags                = {
    Terraform = "true"
    Environment = "dev"
  }
  vpc_tags = {
    Name = "${var.namespace}-VPC"
    Environment = "dev"
  }
}







