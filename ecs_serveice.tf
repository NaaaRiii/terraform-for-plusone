resource "aws_ecs_service" "plusone_service" {
  name            = "service-for-plusone"
  cluster         = aws_ecs_cluster.main.id
  desired_count   = 1
  launch_type     = "FARGATE"

  task_definition = aws_ecs_task_definition.plusone_task.arn

  network_configuration {
    subnets          = [
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_c.id
    ]
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = false
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
