variable "yolo5_instance_type" {
  description = "the instance type of the specific region- for yolo5"
  type        = string
}

variable "yolo5_ami_id" {
  description = "the ami id of the specific region for yolo5"
  type        = string
}

variable "vpc_id" {
  description = "the created vpc ID"
  type        = string
}

variable "az_1" {
description = "first availability zone"
type        = string
}

variable "az_2" {
  description = "second availability zone"
  type        = string
}

variable "subnet_ids" {
  description = "subnet ids from vpc"
  type        = list(string)
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

variable "key_name" {
  description = "aws key name"
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