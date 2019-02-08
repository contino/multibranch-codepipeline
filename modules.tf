module "pipeline" {
  source = "./modules/pipeline"
  repo   = "${var.git_repository_name}"
}
