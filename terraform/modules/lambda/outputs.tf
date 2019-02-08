output "lambda_function_prEvents_arn" {
  value = "${data.aws_lambda_function.prEvents.arn}"
}

output "lambda_function_branchEvents_arn" {
  value = "${data.aws_lambda_function.branchEvents.arn}"
}
