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