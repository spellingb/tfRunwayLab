variable "environment" {}
variable "customer" {}
variable "namespace" {}
variable "region" {}
variable "keypair" {}
variable "statebucket" {

}
variable "os" {
  default = "linux"
}
variable "instance_type" {
  description = "list of instance types allowed for autoscale group"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t2.micro", "t2.small"], var.instance_type)
    error_message = "Instance type not allowed..."
  }
}
