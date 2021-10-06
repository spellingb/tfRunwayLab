variable "environment" {
    default = "dev"
}
variable "customer" {
    default = "test"
}
variable "namespace" {
    default = "test"
}
variable "region" {
    description   = "AWS region"
    type          = string
    default       = "us-west-1"

    #validation {
    #    condition     = can(regex("^us-(east|west)-[1-2]$", var.region))
    #    error_message = "Region is not in the U.S. of A. Keep it 'merican buddy..."
    #}
}

variable "CiderBlock" {
    type    = map
    default = {
        "us-east-1" = "10.100"
        "us-east-2" = "10.110"
        "us-west-1" = "10.200"
        "us-west-2" = "10.210"
    }
}

locals {
    priv = 100
    pub = 200
    maxsubnets = 2
}

data "aws_availability_zones" "AZs" {
    state = "available"
}

locals {
    AZs = data.aws_availability_zones.AZs.names
}

locals {
    priv_networks = [
        for az in local.AZs:
            "${lookup(var.CiderBlock, var.region)}.${local.priv + index(local.AZs, az)}.0/24"
            if index(local.AZs, az) < local.maxsubnets
    ]
    pub_networks = [
        for az in local.AZs:
            "${lookup(var.CiderBlock, var.region)}.${local.pub + index(local.AZs, az)}.0/24"
            if index(local.AZs, az) < local.maxsubnets
    ]
}
