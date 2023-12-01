output "psb_repo_arn" {
  value = aws_ecr_repository.psb_img_repos.arn
}

output "psb_repo_id" {
  value = aws_ecr_repository.psb_img_repos.registry_id
}

output "psb_repo_url" {
  value = aws_ecr_repository.psb_img_repos.repository_url
}
