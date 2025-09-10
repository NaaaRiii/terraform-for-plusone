# ========================================
# Lambda関数用IAMロール
# ========================================
resource "aws_iam_role" "rds_scheduler_lambda_role" {
  name = "rds-scheduler-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda基本実行ポリシー
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.rds_scheduler_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# RDS操作用カスタムポリシー
resource "aws_iam_role_policy" "rds_scheduler_policy" {
  name = "rds-scheduler-policy"
  role = aws_iam_role.rds_scheduler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# ========================================
# Lambda関数用のZIPファイル作成
# ========================================
data "archive_file" "rds_scheduler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/rds-scheduler"
  output_path = "${path.module}/lambda/rds-scheduler.zip"
  
  depends_on = [
    null_resource.install_lambda_dependencies
  ]
}

# Lambdaの依存関係インストール
resource "null_resource" "install_lambda_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/lambda/rds-scheduler/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/lambda/rds-scheduler
      python3 -m pip install -r requirements.txt -t .
    EOT
  }
}

# ========================================
# Lambda関数 - RDS起動用
# ========================================
resource "aws_lambda_function" "rds_start" {
  filename         = data.archive_file.rds_scheduler_zip.output_path
  function_name    = "rds-start-scheduler"
  role            = aws_iam_role.rds_scheduler_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.13"
  timeout         = 60

  source_code_hash = data.archive_file.rds_scheduler_zip.output_base64sha256

  environment {
    variables = {
      RDS_INSTANCE_ID = aws_db_instance.mydb.identifier
      ACTION         = "start"
      DRY_RUN        = "false"  # 初期はテストモード
    }
  }

  tags = {
    Name = "RDS Start Scheduler"
  }
}

# ========================================
# Lambda関数 - RDS停止用
# ========================================
resource "aws_lambda_function" "rds_stop" {
  filename         = data.archive_file.rds_scheduler_zip.output_path
  function_name    = "rds-stop-scheduler"
  role            = aws_iam_role.rds_scheduler_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.13"
  timeout         = 60

  source_code_hash = data.archive_file.rds_scheduler_zip.output_base64sha256

  environment {
    variables = {
      RDS_INSTANCE_ID = aws_db_instance.mydb.identifier
      ACTION         = "stop"
      DRY_RUN        = "false"  # 初期はテストモード
    }
  }

  tags = {
    Name = "RDS Stop Scheduler"
  }
}

# ========================================
# EventBridge ルール - RDS起動（平日9:50 JST）
# ========================================
resource "aws_cloudwatch_event_rule" "rds_start_schedule" {
  name                = "rds-start-schedule"
  description         = "RDS起動スケジュール - 平日9:50 JST"
  schedule_expression = "cron(50 0 ? * MON-FRI *)"  # UTC 0:50 = JST 9:50

  tags = {
    Name = "RDS Start Schedule"
  }
}

resource "aws_cloudwatch_event_target" "rds_start_target" {
  rule      = aws_cloudwatch_event_rule.rds_start_schedule.name
  target_id = "RDSStartLambdaTarget"
  arn       = aws_lambda_function.rds_start.arn
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_start_schedule.arn
}

# ========================================
# EventBridge ルール - RDS停止（平日18:00 JST）
# ========================================
resource "aws_cloudwatch_event_rule" "rds_stop_schedule" {
  name                = "rds-stop-schedule"
  description         = "RDS停止スケジュール - 平日18:00 JST"
  schedule_expression = "cron(0 9 ? * MON-FRI *)"   # UTC 9:00 = JST 18:00

  tags = {
    Name = "RDS Stop Schedule"
  }
}

resource "aws_cloudwatch_event_target" "rds_stop_target" {
  rule      = aws_cloudwatch_event_rule.rds_stop_schedule.name
  target_id = "RDSStopLambdaTarget"
  arn       = aws_lambda_function.rds_stop.arn
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_stop_schedule.arn
}

# ========================================
# 出力
# ========================================
output "rds_start_lambda_arn" {
  value = aws_lambda_function.rds_start.arn
}

output "rds_stop_lambda_arn" {
  value = aws_lambda_function.rds_stop.arn
}

output "rds_start_schedule" {
  value = aws_cloudwatch_event_rule.rds_start_schedule.schedule_expression
}

output "rds_stop_schedule" {
  value = aws_cloudwatch_event_rule.rds_stop_schedule.schedule_expression
}
