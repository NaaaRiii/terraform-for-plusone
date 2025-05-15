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
        { name = "RDS_ENDPOINT",  value = "terraform-20250203085926710300000003.c3g84cqawa82.ap-northeast-1.rds.amazonaws.com" },
      ],

      secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = data.aws_secretsmanager_secret_version.db_password.arn
      },
      {
        name      = "DB_USER"
        valueFrom = data.aws_secretsmanager_secret_version.db_user.arn
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

resource "aws_cloudwatch_log_group" "plusone_log_group" {
  name              = "/ecs/plusone-app"
  retention_in_days = 7

  tags = {
    Name = "plusone-log-group"
  }
}
