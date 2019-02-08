data "aws_lambda_function" "branchEvents" {
  function_name = "${var.lambda_function_branchEvents_name}"

  #do not remove qualifier
  qualifier = ""
}

data "aws_lambda_function" "prEvents" {
  function_name = "${var.lambda_function_prEvents_name}"

  #do not remove qualifier
  qualifier = ""
}
