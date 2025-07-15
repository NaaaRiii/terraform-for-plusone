resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-for-plusone"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-for-pubsub"
  }
}

#############################
# Public Subnet
#############################
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block             = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-c"
  }
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt"
  }
}

# IGWへのデフォルトルート追加
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# 上記ルートテーブルをPublic Subnetに関連付け
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c_assoc" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# プライベートサブネット (ap-northeast-1a)
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-for-plusone-a"
  }
}

# プライベートサブネット (ap-northeast-1c)
resource "aws_subnet" "private_subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-for-plusone-c"
  }
}


# RDS サブネットグループ
resource "aws_db_subnet_group" "mydb_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_c.id,
  ]

  tags = {
    Name = "rds-subnet-group"
  }
}

 resource "aws_eip" "nat_gw_eip_a" {
   tags = {
     Name = "nat-gw-eip-a"
   }
 }

 resource "aws_eip" "nat_gw_eip_c" {
   tags = {
     Name = "nat-gw-eip-c"
   }
 }

 resource "aws_nat_gateway" "nat_gw_a" {
   allocation_id = aws_eip.nat_gw_eip_a.id
   subnet_id     = aws_subnet.public_a.id
   tags = {
     Name = "nat-gw-a"
   }
 }

 resource "aws_nat_gateway" "nat_gw_c" {
   allocation_id = aws_eip.nat_gw_eip_c.id
   subnet_id     = aws_subnet.public_c.id
   tags = {
     Name = "nat-gw-c"
   }
 }

 resource "aws_route_table" "private_a" {
   vpc_id = aws_vpc.main.id
   tags = { Name = "private-rt-a" }
 }

 resource "aws_route_table" "private_c" {
   vpc_id = aws_vpc.main.id
   tags = { Name = "private-rt-c" }
 }

 # Private Subnet A用のNAT Gatewayへのデフォルトルート
 resource "aws_route" "private_a_default_route" {
   route_table_id         = aws_route_table.private_a.id
   destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id         = aws_nat_gateway.nat_gw_a.id
 }

 # Private Subnet C用のNAT Gatewayへのデフォルトルート
 resource "aws_route" "private_c_default_route" {
   route_table_id         = aws_route_table.private_c.id
   destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id         = aws_nat_gateway.nat_gw_c.id
 }

 # Private Subnet Aに関連付け
 resource "aws_route_table_association" "private_a_assoc" {
   route_table_id = aws_route_table.private_a.id
   subnet_id      = aws_subnet.private_subnet_a.id
 }

 # Private Subnet Cに関連付け
 resource "aws_route_table_association" "private_c_assoc" {
   route_table_id = aws_route_table.private_c.id
   subnet_id      = aws_subnet.private_subnet_c.id
 }
