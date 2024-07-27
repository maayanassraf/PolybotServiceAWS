terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }
#
#  backend "s3" {
#    bucket = "maayana-tfstate-bucket"
#    key    = "tfstate.json"
#    region = "eu-north-1"
#  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "tf-${var.owner}-vpc"
  cidr = var.vpc_cidr

  azs                 = [var.az_1, var.az_2]
  public_subnets      = var.vpc_public_subnets

  enable_nat_gateway = false

  tags = {
    Name        = "maayana-vpc-tf"
    Env         = var.env
    Terraform   = true
  }
}

resource "aws_s3_bucket" "tf-maayana-images-bucket" {
  bucket = "tf-${var.owner}-images-bucket-${var.region}"
  tags = {
    Name        = "tf-maayana-images-bucket"
    Env         = var.env
    Terraform   = true
  }
  force_destroy = true
}

resource "aws_dynamodb_table" "tf-maayana-predictions-dynamodb-table" {
  name           = "tf-${var.owner}-predictions-dynamodb-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "prediction_id"

  attribute {
    name = "prediction_id"
    type = "S"
  }
}
resource "aws_sqs_queue" "tf-maayana-project-queue" {
  name                      = "tf-${var.owner}-project-queue"
  message_retention_seconds = 86400
  sqs_managed_sse_enabled = true

  tags = {
    Environment = var.env
  }
}

#resource "aws_key_pair" "key-pair" {
#  key_name   = "tf-${var.owner}-key-${var.region}"
#  public_key = file("rsa.pub")
#}

module "polybot" {
  source = "./modules/polybot"

  polybot_ami_id        = var.polybot_ami_id
  polybot_instance_type = var.polybot_instance_type
  region                = var.region
  owner                 = var.owner
  zone_id               = var.zone_id
  vpc_id                = module.app_vpc.vpc_id
  subnet_ids            = module.app_vpc.public_subnets
  images_bucket_arn     = aws_s3_bucket.tf-maayana-images-bucket.arn
  dynamo_db_arn         = aws_dynamodb_table.tf-maayana-predictions-dynamodb-table.arn
  sqs_arn               = aws_sqs_queue.tf-maayana-project-queue.arn
  key_name              = "123"
  botToken              = var.botToken
  key                   = var.key
  main-region           = var.main-region
 }

module "yolo5" {
  source = "./modules/yolo5"

  yolo5_instance_type   = var.yolo5_instance_type
  yolo5_ami_id          = var.yolo5_ami_id
  vpc_id                = module.app_vpc.vpc_id
  owner                 = var.owner
  az_1                  = var.az_1
  az_2                  = var.az_2
  subnet_ids            = module.app_vpc.public_subnets
  images_bucket_arn     = aws_s3_bucket.tf-maayana-images-bucket.arn
  dynamo_db_arn         = aws_dynamodb_table.tf-maayana-predictions-dynamodb-table.arn
  sqs_arn               = aws_sqs_queue.tf-maayana-project-queue.arn
  key_name              = "123"
  key                   = var.key
  main-region           = var.main-region
}

#lt_id = module.yolo5.launch_template_id