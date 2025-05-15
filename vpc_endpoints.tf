########################################################################
# ECR API Endpoint (Interface)
########################################################################
resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_c.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ecr-api-endpoint"
  }
}

########################################################################
# ECR DKR Endpoint (Interface)
########################################################################
resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type  = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_c.id
  ]
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ecr-dkr-endpoint"
  }
}

########################################################################
# S3 (Gateway Endpoint)
########################################################################
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"

  # 例: VPCのメインルートテーブルIDなどを指定
  route_table_ids   = [aws_vpc.main.main_route_table_id]

  tags = {
    Name = "s3-endpoint"
  }
}


########################################################################
#VPC Endpoint (Interface Endpoint) for CloudWatch Logs
########################################################################
resource "aws_vpc_endpoint" "cw_logs_endpoint" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.ap-northeast-1.logs"  # リージョンに合わせる
  vpc_endpoint_type  = "Interface"

  # ECS タスクが配置されるプライベートサブネットを指定
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_c.id
  ]

  # 上記で作成したセキュリティグループ
  security_group_ids = [aws_security_group.vpce_logs_sg.id]

  # private DNS を有効にすると、CloudWatch Logs の *.amazonaws.com を
  # プライベートIPで解決します
  private_dns_enabled = true

  tags = {
    Name = "cw-logs-endpoint"
  }
}