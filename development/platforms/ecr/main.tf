resource "aws_ecr_repository" "psb_img_repos" {
  name         = var.name
  force_delete = true
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository_policy" "psb_img_repos_policy" {
  repository = aws_ecr_repository.psb_img_repos.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ecr:*"
        Effect = "Allow"
        Sid    = "AllowAll"
        Principal = {
          AWS = [
            "arn:aws:iam::235824954020:user/jungmin1237",
          ]
        }
      },
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "psb_img_repos_lifepolicy" {
  repository = aws_ecr_repository.psb_img_repos.name

  policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 1,
          "description" : "Expire images older than 14 days",
          "selection" : {
            "tagStatus" : "untagged",
            "countType" : "sinceImagePushed",
            "countUnit" : "days",
            "countNumber" : 14
          },
          "action" : {
            "type" : "expire"
          }
        }
      ]
    }
  )

}
