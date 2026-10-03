variable "allowed_browser_cidr" {
  description = "Your public IPv4 address followed by /32"
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.allowed_browser_cidr)) &&
      endswith(var.allowed_browser_cidr, "/32")
    )
    error_message = "Enter one public IPv4 address followed by /32."
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "ticket-load-balancer"
  description = "Traffic rules for the ticket load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ticket-load-balancer"
  }
}

resource "aws_security_group" "application" {
  name        = "ticket-application"
  description = "Traffic rules for the ticket application"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ticket-application"
  }
}

resource "aws_security_group" "database" {
  name        = "ticket-database"
  description = "Traffic rules for the ticket database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ticket-database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "browser_to_lb" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTP from your browser"
  cidr_ipv4         = var.allowed_browser_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "lb_to_app" {
  security_group_id            = aws_security_group.load_balancer.id
  description                  = "Send requests to the application"
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_vpc_security_group_ingress_rule" "app_from_lb" {
  security_group_id            = aws_security_group.application.id
  description                  = "Application requests only from load balancer"
  referenced_security_group_id = aws_security_group.load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.application.id
  description       = "HTTPS for image downloads and AWS services"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.application.id
  description                  = "Connect to PostgreSQL"
  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL only from the application"
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}