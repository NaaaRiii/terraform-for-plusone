# ========================================
# ECS Cluster
# ========================================
resource "aws_ecs_cluster" "main" {
  name = "cluster-for-plusone"
  
  tags = {
    Name = "cluster-for-plusone"
  }
}

# ========================================
# ECS IAM Roles and Policies
# ========================================

# Data sources for IAM policies
data "aws_iam_policy_document" "ecs_task_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Task Execution Role (for pulling images and writing logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-plusone"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

# Attach policies to execution role
resource "aws_iam_role_policy_attachment" "ecs_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole-plusone"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role_policy.json
}

# ========================================
# ECS Task Definition
# ========================================
resource "aws_ecs_task_definition" "plusone_task" {
  family                   = "plusone-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "plusone-container",
      image     = "133286692900.dkr.ecr.ap-northeast-1.amazonaws.com/plusone-rails:latest",
      cpu       = 0,
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000,
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        { name = "RAILS_ENV",     value = "production" },
        { name = "DB_NAME",       value = "plusonedb_production" },
        { name = "RDS_ENDPOINT",  value = "terraform-2025070808344858690000000d.c3g84cqawa82.ap-northeast-1.rds.amazonaws.com" },
      ],

      secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = data.aws_secretsmanager_secret_version.db_password.arn
      },
      {
        name      = "DB_USER"
        valueFrom = data.aws_secretsmanager_secret_version.db_user.arn
      },
      {
        name      = "SECRET_KEY_BASE"
        valueFrom = data.aws_secretsmanager_secret_version.secret_key_base.arn
      },
      {
        name      = "COGNITO_USER_POOL_ID"
        valueFrom = data.aws_secretsmanager_secret_version.cognito_user_pool_id.arn
      },
      {
        name      = "COGNITO_APP_CLIENT_ID"
        valueFrom = data.aws_secretsmanager_secret_version.cognito_app_client_id.arn
      },
      {
        name      = "GUEST_EMAIL"
        valueFrom = data.aws_secretsmanager_secret_version.guest_email.arn
      },
      {
        name      = "GUEST_PASSWORD"
        valueFrom = data.aws_secretsmanager_secret_version.guest_password.arn
      }
    ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.plusone_log_group.name
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "rails"
        }
      }
    }
  ])
}

# ========================================
# ECS Service
# ========================================
resource "aws_ecs_service" "plusone_service" {
  name            = "service-for-plusone"
  cluster         = aws_ecs_cluster.main.id
  desired_count   = 1
  launch_type     = "FARGATE"

  task_definition = aws_ecs_task_definition.plusone_task.arn
  platform_version = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets          = [
      aws_subnet.public_a.id,
      aws_subnet.public_c.id
    ]
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.plusone-tg.arn
    container_name   = "plusone-container"
    container_port   = 3000
  }

  # タスク定義更新時にサービスを自動更新するには↓があると便利
  deployment_controller {
    type = "ECS"
  }

  health_check_grace_period_seconds = 600

  depends_on = [aws_ecs_task_definition.plusone_task]
} 