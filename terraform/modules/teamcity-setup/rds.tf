# ------------------------------------------------------------------------------

locals {
  database_password = var.database_password != "" ? var.database_password : random_password.database[0].result
}

# ------------------------------------------------------------------------------
resource "random_password" "database" {
  count = var.database_password != "" ? 0 : 1

  length  = 24
  special = true
}

# Database subnet group (required for db instance creation)
resource "aws_db_subnet_group" "this" {
  name       = "teamcity-db-subnet-group"
  subnet_ids = [for k, v in aws_subnet.private : v.id]

  tags = {
    Name        = "teamcity-db-subnet-group"
    Description = "AWS RDS subnet group"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "teamcity-db"
  instance_class         = var.database_machine_type
  engine                 = var.database_engine
  db_name                = var.database_name
  username               = var.database_user
  password               = local.database_password
  db_subnet_group_name   = aws_db_subnet_group.this.id
  vpc_security_group_ids = [] // FIXME
  multi_az               = length(var.vpc_network.availability_zones) > 1 ? true : false

  tags = {
    Name        = "teamcity-db"
    Description = "TeamCity RDS database instance"
  }
}

