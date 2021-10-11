resource "aws_security_group" "lb_security_group" {
  name        = "lb_security_group"
  description = "Allow inbound web ports to LB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id


  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.namespace}-lb_Web_access"
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_asg_security_group" {
  name        = "ec2_asg_security_group"
  description = "allow http to app servers from lb"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  depends_on = [
    aws_security_group.lb_security_group
  ]

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "${var.namespace}-ec2_asg_security_group"
    Environment = var.environment
  }

}