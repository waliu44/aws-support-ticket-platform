resource "aws_db_subnet_group" "tickets" {
  name = "ticket-database-subnets"

  subnet_ids = concat(
    aws_subnet.database[*].id,
    [aws_subnet.database_extra.id]
  )

  tags = {
    Name = "ticket-database-subnets"
  }
}

resource "aws_db_instance" "tickets" {
  identifier = "ticket-postgres"

  engine            = "postgres"
  engine_version    = "17"
  instance_class    = "db.t4g.micro"
  availability_zone = "us-east-2c"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "tickets"
  username = "ticket_admin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.tickets.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  multi_az = false

  backup_retention_period = 7
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "ticket-postgres-final"

  tags = {
    Name = "ticket-postgres"
  }
}

resource "aws_secretsmanager_secret" "application_database" {
  name                    = "ticket-platform/application-database"
  description             = "Database credentials for the ticket application"
  recovery_window_in_days = 7

  tags = {
    Name = "ticket-application-database-secret"
  }
}