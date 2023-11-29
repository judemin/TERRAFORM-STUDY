############ Gateway ##############
# Internet gateway
resource "aws_internet_gateway" "goorm_internet_gw" {
  vpc_id = aws_vpc.goorm_vpc.id

  tags = {
    Name = "goorm_internet_gw"
  }
}

# Route table
resource "aws_route_table" "goorm_route_table" {
  vpc_id = aws_vpc.goorm_vpc.id

  tags = {
    Name = "goorm_route_table"
  }
}

# Route
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
