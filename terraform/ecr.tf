# Registro privado de imágenes Docker en AWS (como Docker Hub pero tuyo)
resource "aws_ecr_repository" "users_service" {
  name                 = "users-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "users-service"
  }
}

resource "aws_ecr_repository" "products_service" {
  name                 = "products-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "products-service"
  }
}

# Política de limpieza: mantiene solo las últimas 10 imágenes para no gastar espacio
resource "aws_ecr_lifecycle_policy" "users_service" {
  repository = aws_ecr_repository.users_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "products_service" {
  repository = aws_ecr_repository.products_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
