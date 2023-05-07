# create subnetGroup
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = data.aws_subnet_ids.default.ids

  tags = {
    Name = "My DB subnet group"
  }
}

# create databases
resource "aws_db_instance" "example" {
  identifier_prefix    = "terraform-up-and-running"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  engine               = "mysql"
  allocated_storage    = 10 # 10G
  instance_class       = "db.t2.micro"
  name                 = "example_database"
  username             = "admin"
  password             = var.db_password
}
