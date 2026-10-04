resource "aws_lb" "application" {
  name               = "ticket-load-balancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.load_balancer.id
  ]

  subnets = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "application" {
  name        = "ticket-application"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "application" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}