output "repo_arn" {
  value = "${data.aws_codecommit_repository.main_repo.arn}"
}
