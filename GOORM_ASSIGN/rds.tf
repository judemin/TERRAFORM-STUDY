############ Database SG ##############
resource "aws_security_group" "goorm-private-db-sg" {
  name        = "goorm-private-db-sg"
  description = "database security group"
  vpc_id      = aws_vpc.goorm_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server_sg.id]
  }

  # Can communicate only when manually set egress (outbound)
  egress {
    from_port = 0
    to_port   = 0
    # -1 means all protocol
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "goorm-private-db-sg"
  }
}

############# RDS Cluster ###############
resource "aws_rds_cluster" "goorm-aurora-mysql-db" {
  cluster_identifier     = "goorm-database"
  engine_mode            = "provisioned"
  db_subnet_group_name   = aws_db_subnet_group.goorm_private_db_subnet_grp.name
  vpc_security_group_ids = [aws_security_group.goorm-private-db-sg.id]
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.11.1"
  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]
  database_name   = "goormPrivatedb"
  master_username = "root"
  master_password = "root1234"
  # skip_final_snapshot = false is cannot controlled by terraform destroy
  skip_final_snapshot = true
}

# rds instance writer instance endpoint output for mysql, 3-tier architecture config
output "rds_writer_endpoint" {
  value = aws_rds_cluster.goorm-aurora-mysql-db.endpoint
}

############# RDS Instance ##############
resource "aws_rds_cluster_instance" "aurora-mysql-db-instance" {
  # 2 instances (reader, writer)
  count              = 2
  identifier         = "goorm-database-${count.index}"
  cluster_identifier = aws_rds_cluster.goorm-aurora-mysql-db.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.goorm-aurora-mysql-db.engine
  engine_version     = aws_rds_cluster.goorm-aurora-mysql-db.engine_version
}
