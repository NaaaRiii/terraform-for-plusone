resource "aws_db_instance" "mydb" {
  allocated_storage   	 = 20
  engine              	 = "mysql"
  engine_version      	 = "8.0"
  instance_class      	 = "db.t3.micro"
  db_name             	 = "plusonedb_production" 
	username = var.DATABASE_DEV_USER
	password = var.DATABASE_DEV_PASSWORD
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = _db_subnet_awsgroup.mydb_subnet_group.name
  skip_final_snapshot 	 = true
}

output "rds_endpoint" {
	value = aws_db_instance.mydb.endpoint
}