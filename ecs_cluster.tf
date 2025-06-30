resource "aws_ecs_cluster" "main" {
  name = "cluster-for-plusone"
  
  tags = {
    Name = "cluster-for-plusone"
  }
}
