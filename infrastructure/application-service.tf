resource "aws_ecs_task_definition" "application" {
  family                   = "support-ticket-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.application_execution.arn
  task_role_arn      = aws_iam_role.application_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "${aws_ecr_repository.application.repository_url}:${var.application_image_tag}"
      essential = true

      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
        protocol      = "tcp"
      }]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.tickets.address
        },
        {
          name  = "DB_PORT"
          value = tostring(aws_db_instance.tickets.port)
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.tickets.db_name
        },
        {
          name  = "DB_SSLMODE"
          value = "verify-full"
        },
        {
          name  = "DB_SSLROOTCERT"
          value = "/project/app/global-bundle.pem"
        }
      ]

      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.application_database.arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.application_database.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "web"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "application" {
  name            = "ticket-service"
  cluster         = aws_ecs_cluster.application.id
  task_definition = aws_ecs_task_definition.application.arn

  desired_count    = var.application_task_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  health_check_grace_period_seconds = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets = aws_subnet.public[*].id

    security_groups = [
      aws_security_group.application.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.application.arn
    container_name   = "web"
    container_port   = 5000
  }

  depends_on = [
    aws_lb_listener.application,
    aws_iam_role_policy.application_execution,
    aws_route.public_internet,
    aws_route_table_association.public
  ]
}