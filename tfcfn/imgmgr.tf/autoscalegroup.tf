# buckets
resource "aws_s3_bucket" "img_mgr_bucket" {
  bucket_prefix = "${var.namespace}-${var.environment}-imgmgr-"
  acl           = "private"
  force_destroy = true

  tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }
}

#load balancer
resource "aws_lb" "img_mgr_lb" {
  name = "imgmgr-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_list

  enable_deletion_protection = false

  tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "img_mgr_target_group" {
  name                          = "imgmgr-tg-${var.environment}"
  port                          = 80
  load_balancing_algorithm_type = "round_robin"
  target_type                   = "instance"
  protocol = "HTTP"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  deregistration_delay = 10


  health_check {
    enabled             = true
    healthy_threshold   = 2
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 6
  }
  tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener" "img_mgr_listener" {
  load_balancer_arn = aws_lb.img_mgr_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action { 
    type             = "forward"
    target_group_arn = aws_lb_target_group.img_mgr_target_group.arn
  }
  tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }
}

#launch template
resource "aws_launch_template" "img_mgr_lt" {
  name = "img-mgr-${var.environment}-lt"

  disable_api_termination = false

  ebs_optimized = false

  iam_instance_profile {
    name = aws_iam_instance_profile.img_mgr_profile.name
  }

  image_id = data.aws_ami.ami.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  key_name = var.keypair

  monitoring {
    enabled = true
  }


  vpc_security_group_ids = [aws_security_group.ec2_asg_security_group.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.namespace}-ImgMgr"
      Environment = var.environment
    }
  }
  user_data = base64encode(local.userdata_linux)
  #user_data = filebase64("${path.module}/example.sh")
}

# autoscale group
resource "aws_placement_group" "imgmgr" {
  name     = "imgmgr-${var.environment}"
  strategy = "spread"
}

resource "aws_autoscaling_group" "img_mgr_asg" {
  name                      = "${var.namespace}-${var.environment}-asg"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.img_mgr_target_group.arn]
  #load_balancers = [aws_lb.img_mgr_lb.arn] #aws_lb_target_group.img_mgr_target_group.arn]
  placement_group           = aws_placement_group.imgmgr.id
  launch_template {
    id = aws_launch_template.img_mgr_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier       = data.terraform_remote_state.vpc.outputs.private_subnet_list

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}









