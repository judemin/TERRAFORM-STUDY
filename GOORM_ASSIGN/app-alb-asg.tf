############ Security Group #############
# Application Load Balancer SG
resource "aws_security_group" "goorm_app_alb_security_group" {
  name        = "goorm_app_alb_security_group"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.goorm_vpc.id

  ingress {
    description = "HTTP from Web Instance"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.web_server_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "goorm_app_alb_security_group"
  }
}

############ App Instance SG ##############
resource "aws_security_group" "app_server_sg" {
  name        = "app_server_sg"
  description = "allow 22, 80"
  vpc_id      = aws_vpc.goorm_vpc.id

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.goorm_app_alb_security_group.id]
  }
}

resource "aws_security_group_rule" "appsg_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server_sg.id
  description       = "ssh"
}

resource "aws_security_group_rule" "appsg_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server_sg.id
  description       = "outbound"
}

######## Application Load Balancer #########
resource "aws_lb" "goorm-app-alb" {
  name               = "goorm-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.goorm_app_alb_security_group.id]
  subnets = [
    aws_subnet.goorm_subnet_a.id,
    aws_subnet.goorm_subnet_c.id
  ]
}

# Send HTTP request to target group
resource "aws_lb_listener" "goorm-app-alb-listener" {
  load_balancer_arn = aws_lb.goorm-app-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.goorm-app-alb-target-group.arn
  }
}

resource "aws_lb_target_group" "goorm-app-alb-target-group" {
  name     = "goorm-app-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.goorm_vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

######## Auto Scaling Group #########
resource "aws_launch_configuration" "goorm-app-launch-config" {
  name            = "goorm-app-launchconfig"
  image_id        = "ami-01123b84e2a4fba05"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app_server_sg.id]

  user_data = <<-EOF
    #! /bin/bash
    sudo yum update
    sudo yum install nginx -y
    sudo su
    cd /usr/share/nginx/html/
    sudo rm index.html
    echo "<h1>Hello, World! You are now in private app<h1/>" > index.html
    cd ~
    sudo service nginx start
    sudo chkconfig nginx on
    sudo service nginx status
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "goorm-app-asg" {
  name                 = "goorm-app-asg"
  launch_configuration = aws_launch_configuration.goorm-app-launch-config.name
  vpc_zone_identifier = [
    aws_subnet.goorm_subnet_a.id,
    aws_subnet.goorm_subnet_c.id
  ]

  target_group_arns = [aws_lb_target_group.goorm-app-alb-target-group.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "name"
    value               = "goorm-app-asg"
    propagate_at_launch = true
  }
}