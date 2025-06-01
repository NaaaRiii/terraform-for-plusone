########################################################################
#for ECS Task
########################################################################
resource "aws_security_group" "vpce_logs_sg" {
  name   = "vpce-logs-sg"
  vpc_id = aws_vpc.main.id

  # ECSタスク側のセキュリティグループから443を許可
  ingress {
    description     = "Allow ECS task SG to connect over 443"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task_sg.id] 
    # ↑ ECSタスクのSGを指定。タスク→VPC Endpoint(443) の通信を許可
  }

  # Egress を全許可 (または適宜絞り込んでもOK)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpce-logs-sg"
  }
}

########################################################################
#for VPC Endpoint
########################################################################
resource "aws_security_group" "vpce_sg" {
  name   = "vpce-sg-for-plusone"
  vpc_id = aws_vpc.main.id

  # ECSタスクのセキュリティグループからの 443 通信を許可
  ingress {
    description      = "Allow ECS Task SG to connect over 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.ecs_task_sg.id]
  }

  # Egress はデフォルトで全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpce-sg"
  }
}

########################################################################
#ecs用のセキュリティグループ
########################################################################
resource "aws_security_group" "ecs_task_sg" {
  name   = "ecs-sg-for-plusone"
  vpc_id = aws_vpc.main.id

  # Outbound はすべて許可 (デフォルト)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound は必要に応じて設定 (例: ALB からの流入など)
   ingress {
     description = "Allow HTTP from ALB"
     from_port   = 3000
     to_port     = 3000
     protocol    = "tcp"
     security_groups = [aws_security_group.alb_sg.id]
   }

  tags = {
    Name = "ecs-task-sg"
  }
}

########################################################################
# RDS用のセキュリティグループ
########################################################################

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "SG for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description       = "Allow MySQL from ECS Task SG"
    from_port         = 3306
    to_port           = 3306
    protocol          = "tcp"
        security_groups = [
      aws_security_group.ecs_task_sg.id,
      aws_security_group.bastion_sg.id
    ]
  }

  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

########################################################################
#for ALB
########################################################################
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # インバウンドルール: HTTP と HTTPS を外部から許可
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドは全て許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

########################################################################
#bastion_ec2
########################################################################

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from office IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.98.115.117/32"] //https://www.cman.jp/network/support/go_access.cgi
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}