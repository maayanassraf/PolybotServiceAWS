resource "aws_iam_instance_profile" "yolo5_instance_profile" {
  count = var.main-region == true ? 1 : 0
  name = "yolo5_instance_profile"
  role = aws_iam_role.tf-yolo5-role[count.index].name
}

resource "aws_iam_role" "tf-yolo5-role" {
  count = var.main-region == true ? 1 : 0
  name                = "tf-${var.owner}-yolo5-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  managed_policy_arns = [aws_iam_policy.tf-yolo5-s3[count.index].arn, aws_iam_policy.tf-yolo5-sqs[count.index].arn, aws_iam_policy.tf-yolo5-dynamo[count.index].arn]
}

resource "aws_iam_policy" "tf-yolo5-s3" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-${var.owner}-yolo5-s3"
  path        = "/"
  description = "allows to polybot ec2s required access to s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ReadAccessFromImagesFold",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "*"
        },
        {
            "Sid": "WriteAccessToPredictedImagesFold",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy" "tf-yolo5-sqs" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-${var.owner}-yolo5-sqs"
  path        = "/"
  description = "allows to polybot ec2s required access to sqs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Sid": "AmazonSQSGeneralPremissions",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueues"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AmazonSQSWritePremissions",
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy" "tf-yolo5-dynamo" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-${var.owner}-yolo5-dynamo"
  path        = "/"
  description = "allows to polybot ec2s required access to dynamo db table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
        {
            "Sid": "ListAndDescribe",
            "Effect": "Allow",
            "Action": [
                "dynamodb:List*",
                "dynamodb:DescribeReservedCapacity*",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeTimeToLive"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SpecificTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "*"
        }
    ]
  })
}