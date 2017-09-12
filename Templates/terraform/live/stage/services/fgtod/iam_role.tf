data "aws_iam_policy_document" "fgt-instance-assume-role-policy" {
  statement {
    actions = [
      "sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"]
    }
  }
  statement {
    actions = [
      "sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "FortigateRole" {
  name = "${var.aws_region}-${var.environment}-FortigateRole"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.fgt-instance-assume-role-policy.json}"
}
