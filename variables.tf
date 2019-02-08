# AWS REGION

variable "aws_region" {
  description = "AWS Region for the VPC"
  default     = "us-east-1"
}

# Github Repository Project Name

variable "git_repository_name" {
  description = "Repository name on CodeCommit"
  default     = "trigger-test"
}
