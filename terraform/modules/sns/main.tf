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
  endpoint  = "${var.lambda_function_prEvents_arn}"
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
        "${var.account_number}",
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

resource "aws_lambda_permission" "allow_prEvent" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_function_prEvents_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.prnotifier.arn}"
}
