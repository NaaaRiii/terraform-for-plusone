resource "aws_cloudwatch_log_group" "plusone_log_group" {
  name              = "/ecs/plusone-app"
  retention_in_days = 7
  tags = {
    Name = "plusone-log-group"
  }
}