resource "aws_iam_role" "database_setup_execution" {
  name               = "ticket-database-setup-execution"
  assume_role_policy = local.ecs_role_trust
}

resource "aws_iam_role_policy" "database_setup_execution" {
  name = "ticket-database-setup-permissions"
  role = aws_iam_role.database_setup_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = concat(
      jsondecode(aws_iam_role_policy.application_execution.policy).Statement,
      [
        {
          Sid      = "ReadDatabaseAdministratorSecret"
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = aws_db_instance.tickets.master_user_secret[0].secret_arn
        }
      ]
    )
  })
}

resource "aws_ecs_task_definition" "database_setup" {
  family                   = "ticket-database-setup"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.database_setup_execution.arn
  task_role_arn      = aws_iam_role.application_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    merge(
      jsondecode(aws_ecs_task_definition.application.container_definitions)[0],
      {
        name    = "database-setup"
        command = ["python", "-m", "app.setup_database"]

        mountPoints    = []
        systemControls = []
        volumesFrom    = []


        secrets = [
          {
            name      = "DB_USERNAME"
            valueFrom = "${aws_db_instance.tickets.master_user_secret[0].secret_arn}:username::"
          },
          {
            name      = "DB_PASSWORD"
            valueFrom = "${aws_db_instance.tickets.master_user_secret[0].secret_arn}:password::"
          },
          {
            name      = "APP_DB_USERNAME"
            valueFrom = "${aws_secretsmanager_secret.application_database.arn}:username::"
          },
          {
            name      = "APP_DB_PASSWORD"
            valueFrom = "${aws_secretsmanager_secret.application_database.arn}:password::"
          }
        ]
      }
    )
  ])

  depends_on = [
    aws_iam_role_policy.database_setup_execution
  ]
}