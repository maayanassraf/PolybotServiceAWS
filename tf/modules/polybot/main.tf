
resource "aws_instance" "app_server" {
  count = length(var.subnet_ids)

  ami                         = var.polybot_ami_id
  instance_type               = var.polybot_instance_type
  vpc_security_group_ids      = [aws_security_group.tf-maayana-polybot-sg.id]
  subnet_id                   = var.subnet_ids[count.index]
  associate_public_ip_address = true
  key_name                    = var.key
  iam_instance_profile        =  var.main-region == true ? aws_iam_instance_profile.polybot_instance_profile[0].name : "polybot_instance_profile"
  user_data                   = file("install_docker.sh")

  tags = {
    Name = "${var.owner}-polybot-ec2"
    Terraform = "true"
  }
}

resource "aws_security_group" "tf-maayana-polybot-sg" {
  name        = "tf-maayana-polybot-sg"
  description = "SG for polybot ec2 access"
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

resource "aws_secretsmanager_secret" "tf-botToken" {
  name = "tf-telegram-botToken"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tf-botToken-value" {
  secret_id     = aws_secretsmanager_secret.tf-botToken.id
  secret_string = var.botToken
}

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

resource "aws_lb" "alb" {
  name               = "tf-maayana-polybot-lb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.tf-maayana-polybot-alb-sg.id]
}

resource "aws_security_group" "tf-maayana-polybot-alb-sg" {
  name        = "tf-maayana-polybot-alb-sg"
  description = "SG for polybot alb access"
  vpc_id = var.vpc_id

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
    cidr_blocks = ["91.108.4.0/22"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["149.154.160.0/20"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "polybot-tg" {
  name     = "tf-maayana-polybot-tg"
  port     = 8443
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path     = "/"
    port     = 8443
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
   for_each = {
    for k, v in aws_instance.app_server :
    k => v
  }
  target_group_arn = aws_alb_target_group.polybot-tg.arn
  target_id        = each.value.id
  port             = 8443
}

resource "aws_route53_record" "alb_record" {
  name    = "maayana-polybot-${var.region}"
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
  }
}

resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # get as data source
  certificate_arn   = aws_acm_certificate.alb_cert.arn
  depends_on = [
    aws_acm_certificate_validation.validate_alb_cert
  ]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.polybot-tg.arn
  }
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8443"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.polybot-tg.arn
  }
}

resource "aws_acm_certificate" "alb_cert" {
  domain_name       = aws_route53_record.alb_record.fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_type
  zone_id         = var.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "validate_alb_cert" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}

#data "aws_ami" "ubuntu_ami" {
#  most_recent = true
#  owners      = ["099720109477"]  # Canonical owner ID for Ubuntu AMIs
#
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#  }
#}