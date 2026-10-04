data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  ecs_role_trust = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }

      Action = "sts:AssumeRole"

      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }

        ArnLike = {
          "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role" "application_execution" {
  name               = "ticket-ecs-execution"
  assume_role_policy = local.ecs_role_trust
}

resource "aws_iam_role_policy" "application_execution" {
  name = "ticket-image-logs-and-secret"
  role = aws_iam_role.application_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid      = "AuthenticateToECR"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ReadApplicationImage"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]

        Resource = aws_ecr_repository.application.arn
      },
      {
        Sid    = "WriteApplicationLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.application.arn}:*"
      },
      {
        Sid      = "ReadApplicationDatabaseSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.application_database.arn
      }
    ]
  })
}

resource "aws_iam_role" "application_task" {
  name               = "ticket-application-task"
  assume_role_policy = local.ecs_role_trust
}