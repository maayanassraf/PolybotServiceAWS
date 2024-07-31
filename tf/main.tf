terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }

  backend "s3" {
    bucket = "maayana-tfstate-bucket"
    key    = "tfstate.json"
    region = "eu-north-1"
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "tf-${var.owner}-vpc"
  cidr = var.vpc_cidr

  azs                 = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets      = var.vpc_public_subnets

  enable_nat_gateway = false

  tags = {
    Name        = "tf-${var.owner}-vpc"
    Env         = var.env
    Terraform   = true
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical owner ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

module "resources" {
  source = "./modules/general-resources"

  region = var.region
  owner  = var.owner
  env    = var.env
}

module "polybot" {
  source = "./modules/polybot"

  ami_id                = data.aws_ami.ubuntu_ami.id
  region                = var.region
  owner                 = var.owner
  vpc_id                = module.app_vpc.vpc_id
  subnet_ids            = module.app_vpc.public_subnets
  images_bucket_arn     = module.resources.s3_bucket_arn
  dynamo_db_arn         = module.resources.dynamodb_table_arn
  sqs_arn               = module.resources.sqs_arn
  botToken              = var.botToken
  key                   = var.key
  main-region           = var.main-region
  hosted_zone_name      = var.hosted_zone_name
 }

module "yolo5" {
  source = "./modules/yolo5"

  ami_id                = data.aws_ami.ubuntu_ami.id
  vpc_id                = module.app_vpc.vpc_id
  owner                 = var.owner
  subnet_ids            = module.app_vpc.public_subnets
  images_bucket_arn     = module.resources.s3_bucket_arn
  dynamo_db_arn         = module.resources.dynamodb_table_arn
  sqs_arn               = module.resources.sqs_arn
  key                   = var.key
  main-region           = var.main-region
}
