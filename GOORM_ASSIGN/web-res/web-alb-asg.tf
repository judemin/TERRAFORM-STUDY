############ Security Group #############
# Application Load Balancer SG
resource "aws_security_group" "web_alb_security_group" {
  name        = "web_alb_security_group"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.goorm_vpc.id

  ingress {
    description = "HTTP from Internet"
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
    Name = "web_alb_security_group"
  }
}

# Auto Scaling Group SG
resource "aws_security_group" "web_asg_security_group" {
  name        = "web_asg_security_group"
  description = "ASG Security Group"
  vpc_id      = aws_vpc.goorm_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_asg_security_group"
  }
}

######## Application Load Balancer #########
resource "aws_lb" "web-alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_alb_security_group.id]
  subnets = [
    aws_subnet.goorm_subnet_a.id,
    aws_subnet.goorm_subnet_c.id
  ]
}

# Send HTTP request to target group
resource "aws_lb_listener" "web-alb-listener" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-alb-target-group.arn
  }
}

resource "aws_lb_target_group" "web-alb-target-group" {
  name     = "web-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.goorm_vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

######## Auto Scaling Group #########
resource "aws_launch_configuration" "goorm-web-launconfig" {
  name            = "goorm-web-launconfig"
  image_id        = "ami-01123b84e2a4fba05"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_server_sg.id]

  user_data = <<-EOF
    #! /bin/bash
    sudo yum update
    sudo yum install nginx -y
    sudo service nginx start
    sudo chkconfig nginx on
    sudo service nginx status
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "goorm-web-asg" {
  name                 = "goorm-web-asg"
  launch_configuration = aws_launch_configuration.goorm-web-launconfig.name
  vpc_zone_identifier = [
    aws_subnet.goorm_subnet_a.id,
    aws_subnet.goorm_subnet_c.id
  ]

  target_group_arns = [aws_lb_target_group.web-alb-target-group.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "name"
    value               = "goorm-web-asg"
    propagate_at_launch = true
  }
}