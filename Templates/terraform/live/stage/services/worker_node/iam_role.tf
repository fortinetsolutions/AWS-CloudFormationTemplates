
resource "aws_iam_role" "WorkerNodeRole" {
  name = "${var.aws_region}-${var.environment}-WorkerNodeRole"
  path = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "ec2.amazonaws.com"
          ]
        },
        "Action": [
          "sts:AssumeRole"
        ]
      }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "worker_node_profile" {
  name  = "${var.customer_prefix}-${var.aws_region}-${var.environment}-worker_node_profile"
  role  = "${aws_iam_role.WorkerNodeRole.name}"
}

resource "aws_iam_role_policy" "workernode-role-policy" {
  name = "workernode-role-policy"
  role = "${aws_iam_role.WorkerNodeRole.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":
  [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53domains:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:DescribeAccountLimits",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResource",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescribeStacks",
        "cloudformation:GetStackPolicy",
        "cloudformation:ListStackResources",
        "cloudformation:ListStacks"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
