resource "aws_ecs_cluster" "main" {
  name = "cluster-for-plusone"
  
  # capacity_providers = ["FARGATE", "FARGATE_SPOT"] 
  # オプションとして書いてもOK
  tags = {
    Name = "cluster-for-plusone"
  }
}
