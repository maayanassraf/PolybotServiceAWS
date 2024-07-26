resource "aws_launch_template" "tf-maayana-yolo5-lt" {
  name                 = "tf-${var.owner}-yolo5-lt"
  image_id             = var.yolo5_ami_id
  instance_type        = var.yolo5_instance_type
  user_data            = filebase64("install_docker.sh")
  key_name             = var.key

  tags = {
    Name = "${var.owner}-yolo5-ec2"
    Terraform = "true"
  }
  network_interfaces {
    security_groups = [aws_security_group.tf-maayana-yolo5-sg.id]
    associate_public_ip_address = true
  }
  iam_instance_profile {
    name = var.main-region == true ? aws_iam_instance_profile.yolo5_instance_profile[0].name : "yolo5_instance_profile"
  }
}

resource "aws_autoscaling_group" "tf-maayana-yolo5-asg" {
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids
  name                = "tf-${var.owner}-yolo5-asg"

  launch_template {
    id      = aws_launch_template.tf-maayana-yolo5-lt.id
    version = aws_launch_template.tf-maayana-yolo5-lt.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "yolo5_scale_up"
  autoscaling_group_name = aws_autoscaling_group.tf-maayana-yolo5-asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "yolo5_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "60"
  statistic           = "Average"
  period              = 30
  evaluation_periods  = 1
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tf-maayana-yolo5-asg.name
  }
}

resource "aws_security_group" "tf-maayana-yolo5-sg" {
  name        = "tf-${var.owner}-yolo5-sg"
  description = "SG for yolo5 ec2 access"
  vpc_id = var.vpc_id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "yolo5_instance_profile" {
  count = var.main-region == true ? 1 : 0
  name = "yolo5_instance_profile"
  role = aws_iam_role.tf-maayana-yolo5-role[count.index].name
}

resource "aws_iam_role" "tf-maayana-yolo5-role" {
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
  managed_policy_arns = [aws_iam_policy.tf-maayana-yolo5-s3[count.index].arn, aws_iam_policy.tf-maayana-yolo5-sqs[count.index].arn, aws_iam_policy.tf-maayana-yolo5-dynamo[count.index].arn]
}

resource "aws_iam_policy" "tf-maayana-yolo5-s3" {
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
            "Resource": [
                var.images_bucket_arn
            ]
        },
        {
            "Sid": "ReadAccessFromImagesFold",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": [
                "${var.images_bucket_arn}/images/*"
            ]
        },
        {
            "Sid": "WriteAccessToPredictedImagesFold",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": [
                "${var.images_bucket_arn}/predicted_images/*"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "tf-maayana-yolo5-sqs" {
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
            "Resource": var.sqs_arn
        }
    ]
  })
}

resource "aws_iam_policy" "tf-maayana-yolo5-dynamo" {
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
            "Resource": var.dynamo_db_arn
        }
    ]
  })
}