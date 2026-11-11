# -----------------------------------------------------------------------------
# Container registry: ECR repository
# -----------------------------------------------------------------------------

variable "registry_image_retention_count" {
  description = "Number of images kept in the repository; older ones expire."
  type        = number
  default     = 30
}

resource "aws_ecr_repository" "this" {
  name                 = module.naming.standard["ecr"]
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the newest ${var.registry_image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.registry_image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

output "container_registry_url" {
  description = "URL of the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}
