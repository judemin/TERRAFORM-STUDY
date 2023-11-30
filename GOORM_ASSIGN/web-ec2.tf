# ############ EC2 Instance ##############
# resource "aws_instance" "public_web_a" {
#   ami           = "ami-01123b84e2a4fba05"
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.goorm_subnet_a.id

#   vpc_security_group_ids = [
#     aws_security_group.web_server_sg.id,
#   ]

#   tags = {
#     Name = "public_web_a"
#   }

#   # for aws_instance only
#   # azure: custom_data
#   # gcp: meta_data
#   user_data = <<-EOF
#     #! /bin/bash
#     sudo yum update
#     sudo yum install nginx -y
#     sudo service nginx start
#     sudo chkconfig nginx on
#     sudo service nginx status
#   EOF
# }

# resource "aws_instance" "public_web_c" {
#   ami           = "ami-01123b84e2a4fba05"
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.goorm_subnet_c.id

#   vpc_security_group_ids = [
#     aws_security_group.web_server_sg.id,
#   ]

#   tags = {
#     Name = "public_web_c"
#   }

#   # for aws_instance only
#   # azure: custom_data
#   # gcp: meta_data
#   user_data = <<-EOF
#     #! /bin/bash
#     sudo yum update
#     sudo yum install nginx -y
#     sudo service nginx start
#     sudo chkconfig nginx on
#     sudo service nginx status
#   EOF
# }
