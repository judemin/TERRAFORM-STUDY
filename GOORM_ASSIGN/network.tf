############# VPC ###############
# VPC resource
resource "aws_vpc" "goorm_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "goorm_vpc"
  }
}

# Subnet-a resource
resource "aws_subnet" "goorm_subnet_a" {
  vpc_id                  = aws_vpc.goorm_vpc.id
  cidr_block              = "172.16.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "goorm_subnet_a"
  }
}

# Subnet-c resource
resource "aws_subnet" "goorm_subnet_c" {
  vpc_id                  = aws_vpc.goorm_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "goorm_subnet_c"
  }
}

# Private-Subnet-a resource
resource "aws_subnet" "goorm_private_subnet_a" {
  vpc_id                  = aws_vpc.goorm_vpc.id
  cidr_block              = "172.16.20.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "goorm_private_subnet_a"
  }
}

# Private-Subnet-c resource
resource "aws_subnet" "goorm_private_subnet_c" {
  vpc_id                  = aws_vpc.goorm_vpc.id
  cidr_block              = "172.16.30.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "goorm_private_subnet_c"
  }
}

############ DB Subnet GRP ##############
resource "aws_db_subnet_group" "goorm_private_db_subnet_grp" {
  name = "goorm_private_db_subnet_grp"
  subnet_ids = [
    aws_subnet.goorm_private_db_subnet_a.id,
    aws_subnet.goorm_private_db_subnet_c.id
  ]
}

# Private DB Subnet resources
resource "aws_subnet" "goorm_private_db_subnet_a" {
  vpc_id            = aws_vpc.goorm_vpc.id
  cidr_block        = "172.16.40.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "goorm_private_db_subnet_a"
  }
}

resource "aws_subnet" "goorm_private_db_subnet_c" {
  vpc_id            = aws_vpc.goorm_vpc.id
  cidr_block        = "172.16.50.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "goorm_private_db_subnet_c"
  }
}

########### Network gateway ###########
# Network Gateway for public web subnet
resource "aws_eip" "goorm-ngw-eip-a" {
  domain = "vpc"
}

resource "aws_eip" "goorm-ngw-eip-c" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "goorm-ngw-a" {
  allocation_id = aws_eip.goorm-ngw-eip-a.id
  subnet_id     = aws_subnet.goorm_subnet_a.id
  tags = {
    Name = "goorm-ngw-a"
  }
}

resource "aws_nat_gateway" "goorm-ngw-c" {
  allocation_id = aws_eip.goorm-ngw-eip-c.id
  subnet_id     = aws_subnet.goorm_subnet_c.id
  tags = {
    Name = "goorm-ngw-c"
  }
}

########### Internet gateway ###########
resource "aws_internet_gateway" "goorm_internet_gw" {
  vpc_id = aws_vpc.goorm_vpc.id

  tags = {
    Name = "goorm_internet_gw"
  }
}

########### Route table ###########
resource "aws_route_table" "goorm_route_table" {
  vpc_id = aws_vpc.goorm_vpc.id

  tags = {
    Name = "goorm_route_table"
  }
}

# Route from internet gateway
resource "aws_route" "goorm_route" {
  route_table_id         = aws_route_table.goorm_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.goorm_internet_gw.id
}

resource "aws_route_table_association" "goorm_rtb_sub_a_aasosiation" {
  subnet_id      = aws_subnet.goorm_subnet_a.id
  route_table_id = aws_route_table.goorm_route_table.id
}

# Route table association
resource "aws_route_table_association" "goorm_rtb_sub_c_aasosiation" {
  subnet_id      = aws_subnet.goorm_subnet_c.id
  route_table_id = aws_route_table.goorm_route_table.id
}

# NGW-a to Private Subnet Route Table
resource "aws_route_table" "goorm_private_route_table_a" {
  vpc_id = aws_vpc.goorm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.goorm-ngw-a.id
  }
  tags = {
    Name = "goorm_private_route_table_a"
  }
}

resource "aws_route_table_association" "goorm_rtb_private_sub_a_asoc" {
  subnet_id      = aws_subnet.goorm_private_subnet_a.id
  route_table_id = aws_route_table.goorm_private_route_table_a.id
}

# NGW-c to Private Subnet Route Table
resource "aws_route_table" "goorm_private_route_table_c" {
  vpc_id = aws_vpc.goorm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.goorm-ngw-c.id
  }
  tags = {
    Name = "goorm_private_route_table_c"
  }
}

resource "aws_route_table_association" "goorm_rtb_private_sub_c_asoc" {
  subnet_id      = aws_subnet.goorm_private_subnet_c.id
  route_table_id = aws_route_table.goorm_private_route_table_c.id
}