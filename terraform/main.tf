terraform {
  required_version = "~> 0.11.8"
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {}

module "lambda" {
  source                            = "./modules/lambda"
  lambda_function_branchEvents_name = "dynamic-pipeline-dev-branchEvents"
  lambda_function_prEvents_name     = "dynamic-pipeline-dev-prEvents"
}

module "sns" {
  source                        = "./modules/sns"
  repo                          = "${var.git_repository_name}"
  account_number                = "${data.aws_caller_identity.current.account_id}"
  lambda_function_prEvents_name = "dynamic-pipeline-dev-prEvents"
  lambda_function_prEvents_arn  = "${module.lambda.lambda_function_prEvents_arn}"
}

module "codecommit" {
  source                            = "./modules/codecommit"
  repo                              = "${var.git_repository_name}"
  account_number                    = "${data.aws_caller_identity.current.account_id}"
  lambda_function_branchEvents_name = "dynamic-pipeline-dev-branchEvents"
  lambda_function_branchEvents_arn  = "${module.lambda.lambda_function_branchEvents_arn}"
}

module "cloudwatch" {
  source                       = "./modules/cloudwatch"
  repo                         = "${var.git_repository_name}"
  lambda_function_prEvents_arn = "${module.lambda.lambda_function_prEvents_arn}"
  repo_arn                     = "${module.codecommit.repo_arn}"
}
