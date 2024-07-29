resource "aws_iam_instance_profile" "polybot_instance_profile" {
  count = var.main-region == true ? 1 : 0
  name = "polybot_instance_profile"
  role = aws_iam_role.tf-maayana-polybot-role[count.index].name
}

resource "aws_iam_role" "tf-maayana-polybot-role" {
  count = var.main-region == true ? 1 : 0
  name                = "tf-maayana-polybot-role"
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
  managed_policy_arns = [aws_iam_policy.tf-maayana-polybot-s3[count.index].arn, aws_iam_policy.tf-maayana-polybot-sqs[count.index].arn, aws_iam_policy.tf-maayana-polybot-dynamo[count.index].arn, aws_iam_policy.tf-maayana-polybot-secrets-manager[count.index].arn]
}

resource "aws_iam_policy" "tf-maayana-polybot-secrets-manager" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-maayana-polybot-secrets-manager"
  path        = "/"
  description = "allows to polybot ec2s required access to secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": aws_secretsmanager_secret.tf-botToken.arn
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy" "tf-maayana-polybot-s3" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-maayana-polybot-s3"
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
            "Resource": [
                var.images_bucket_arn
            ]
        },
        {
            "Sid": "WriteAction",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": [
                "${var.images_bucket_arn}/images/*"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "tf-maayana-polybot-sqs" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-maayana-polybot-sqs"
  path        = "/"
  description = "allows to polybot ec2s required access to sqs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
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
                "sqs:SendMessage"
            ],
            "Resource": var.sqs_arn
        }
    ]
  })
}

resource "aws_iam_policy" "tf-maayana-polybot-dynamo" {
  count = var.main-region == true ? 1 : 0
  name        = "tf-maayana-polybot-dynamo"
  path        = "/"
  description = "allows to polybot ec2s required access to dynamo"

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
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": var.dynamo_db_arn
        }
    ]
  })
}