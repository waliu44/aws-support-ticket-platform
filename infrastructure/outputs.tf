output "vpc_id" {
  value = aws_vpc.main.id
}

output "availability_zones" {
  value = local.zones
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "load_balancer_security_group_id" {
  value = aws_security_group.load_balancer.id
}

output "application_security_group_id" {
  value = aws_security_group.application.id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}

output "database_address" {
  value = aws_db_instance.tickets.address
}

output "database_port" {
  value = aws_db_instance.tickets.port
}

output "database_name" {
  value = aws_db_instance.tickets.db_name
}

output "database_admin_secret_arn" {
  value = aws_db_instance.tickets.master_user_secret[0].secret_arn
}

output "database_application_secret_arn" {
  value = aws_secretsmanager_secret.application_database.arn
}