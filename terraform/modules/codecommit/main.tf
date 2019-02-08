data "aws_codecommit_repository" "main_repo" {
  repository_name = "${var.repo}"
}

resource "aws_codecommit_trigger" "branchEvents" {
  repository_name = "${var.repo}"

  trigger {
    name            = "branchEvents"
    events          = ["createReference"]
    destination_arn = "${var.lambda_function_branchEvents_arn}"
  }
}

resource "aws_lambda_permission" "allow_branchEvents" {
  depends_on     = ["aws_codecommit_trigger.branchEvents"]
  statement_id   = "AllowExecutionFromCodeCommitonNewBranch"
  action         = "lambda:InvokeFunction"
  function_name  = "${var.lambda_function_branchEvents_name}"
  principal      = "codecommit.amazonaws.com"
  source_arn     = "${data.aws_codecommit_repository.main_repo.arn}"
  source_account = "${var.account_number}"
}
