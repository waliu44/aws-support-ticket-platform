variable "application_task_count" {
  description = "Keep at zero until the image and database setup are ready"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.application_task_count)
    error_message = "Use zero while setting up, or one to run the application."
  }
}

variable "application_image_tag" {
  description = "Version tag of the application image"
  type        = string
  default     = "v1"
}

resource "aws_ecr_repository" "application" {
  name                 = "support-ticket-app"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "application" {
  name = "ticket-cluster"
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/ecs/support-ticket-app"
  retention_in_days = 14
}