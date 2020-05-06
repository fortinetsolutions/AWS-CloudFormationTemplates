provider "aws" {
  access_key                     = "${var.access_key}"
  secret_key                     = "${var.secret_key}"
  region                         = "${var.aws_region}"
}

# The policy
data "aws_iam_policy_document" "zappa_deployed_lambda" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:CompleteLifecycleAction",
      "cloudformation:CreateStack",
      "cloudformation:UpdateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackResources",
      "cloudformation:ListStackResources",
      "cloudfront:UpdateDistribution",
      "ec2:AttachNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeRouteTables",
      "ec2:DescribeAutoScalingGroups",
      "ec2:DetachNetworkInterface",
      "ec2:ResetNetworkInterfaceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:DeleteNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:ReplaceRoute",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "apigateway:*",
      "iam:*",
      "route53:*",
    ]
    resources = [ "*" ]
  }
  statement {
    effect = "Allow"
    actions = [ "logs:*" ]
    resources = [ "*" ]
  }
  statement {
    effect = "Allow"
    actions = [ "s3:*" ]
    resources = [ "*" ]
  }
  statement {
    effect = "Allow"
    actions = [ "cloudformation:*" ]
    resources = [ "*" ]
  }
  statement {
    effect = "Allow"
    actions = [ "events:*" ]
    resources = [ "arn:aws:events:*" ]
  }
  statement {
    effect = "Allow"
    actions = [ "sns:*" ]
    resources = [ "arn:aws:sns:*:*:*" ]
  }
  statement {
    effect =  "Allow"
    actions = [ "lambda:*" ]
    resources = [ "*" ]
  }
  statement {
     effect =  "Allow"
    actions = [ "cloudfront:*" ]
    resources = [ "*" ]
  }
  statement {
    effect =  "Allow"
    actions = [ "apigateway:*" ]
    resources = [ "arn:aws:apigateway:*:*:*" ]
  }
  statement {
    effect =  "Allow"
    actions = [ "dynamodb:*" ]
    resources = [ "*" ]
  }
}

# the role policy
data "aws_iam_policy_document" "lambda_sync_execution_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The discrete role policy, which connects the IAM role and the policy
resource "aws_iam_role_policy" "lambda_sync_permissions" {
  name   = "fortinet-autoscale-lambda-policy"
  role   = "${aws_iam_role.zappa_deployed_lambda_role.id}"
  policy = "${data.aws_iam_policy_document.zappa_deployed_lambda.json}"
}

# The IAM role actually used by the lambda functions
resource "aws_iam_role" "zappa_deployed_lambda_role" {
  name               = "fortinet-autoscale-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_sync_execution_policy.json}"
}
