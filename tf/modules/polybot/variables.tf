
variable "ami_id" {
  description = "the ami id of the specific region"
  type        = string
}

variable "region" {
  description = "aws region"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets ids from created VPC"
  type        = list(string)
}

variable "vpc_id" {
  description = "the created vpc ID"
  type        = string
}

variable "images_bucket_arn" {
  description = "arn of images bucket"
  type        = string
}

variable "dynamo_db_arn" {
  description = "arn of predictions dynamo db"
  type        = string
}

variable "sqs_arn" {
  description = "arn of sqs"
  type        = string
}

variable "botToken" {
  description = "bot token value"
  type        = string
}

variable "key" {
  description = "key name for the specific region"
  type        = string
}

variable "main-region" {
  description = "declares if region is main - for creating globals items"
  type        = bool
}

variable "owner" {
  description = "declares the project owner"
  type        = string
}

variable "hosted_zone_name" {
  description = "hosted zone name"
  type        = string
}