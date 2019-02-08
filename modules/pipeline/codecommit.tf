data "aws_codecommit_repository" "main_repo" {
  repository_name = "${var.repo}"
}

data "aws_lambda_function" "generic_CLIevent" {
  function_name = "dynamic-pipeline-dev-cliEvents"

  #do not remove qualifier
  qualifier = ""
}

data "aws_lambda_function" "prEvents" {
  function_name = "dynamic-pipeline-dev-prEvents"

  #do not remove qualifier
  qualifier = ""
}

resource "aws_codecommit_trigger" "generic_CLIevent" {
  repository_name = "${var.repo}"

  trigger {
    name            = "generic_CLIevent"
    events          = ["createReference"]
    destination_arn = "${data.aws_lambda_function.generic_CLIevent.arn}"
  }
}

resource "aws_lambda_permission" "allow_generic_CLIevent" {
  depends_on     = ["aws_codecommit_trigger.generic_CLIevent"]
  statement_id   = "AllowExecutionFromCodeCommitonNewBranch"
  action         = "lambda:InvokeFunction"
  function_name  = "dynamic-pipeline-dev-cliEvents"
  principal      = "codecommit.amazonaws.com"
  source_arn     = "${data.aws_codecommit_repository.main_repo.arn}"
  source_account = "655440860013"
}

resource "aws_sns_topic" "prnotifier" {
  name = "codecommit_pr_trigger"
}

resource "aws_sns_topic_policy" "default" {
  arn = "${aws_sns_topic.prnotifier.arn}"

  policy = "${data.aws_iam_policy_document.sns-topic-policy.json}"
}

resource "aws_sns_topic_subscription" "pr_events_notifier" {
  topic_arn = "${aws_sns_topic.prnotifier.arn}"
  protocol  = "lambda"
  endpoint  = "${data.aws_lambda_function.prEvents.arn}"
}

resource "aws_lambda_permission" "allow_pr_notifier" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "dynamic-pipeline-dev-prEvents"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.prnotifier.arn}"
}

resource "aws_cloudwatch_event_rule" "pull_request_event" {
  name        = "capture-pull-request-event"
  description = "Managed by Terraform. Capture all events related to pull-requests"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "resources": [
    "${data.aws_codecommit_repository.main_repo.arn}"
  ],
  "detail-type": [
    "CodeCommit Pull Request State Change"
  ]
}
PATTERN
}

#$.detail.notificationBody
resource "aws_cloudwatch_event_target" "sns" {
  rule       = "${aws_cloudwatch_event_rule.pull_request_event.name}"
  target_id  = "SendToSNS"
  arn        = "${aws_sns_topic.prnotifier.arn}"
  input_path = "$.detail.notificationBody"
}

data "aws_iam_policy_document" "sns-topic-policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "655440860013",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sns_topic.prnotifier.arn}",
    ]

    sid = "__default_statement_ID"
  }

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      "${aws_sns_topic.prnotifier.arn}",
    ]

    sid = "TrustCWEToPublishEventsToMyTopic"
  }
}
