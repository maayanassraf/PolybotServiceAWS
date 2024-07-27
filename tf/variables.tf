variable "az_1" {
description = "first availability zone"
type        = string
}

variable "az_2" {
  description = "second availability zone"
  type        = string
}

variable "region" {
  description = "aws region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "env" {
  description = "describe the environment type"
  type        = string
}

variable "polybot_instance_type" {
  description = "the instance type of the specific region- for polybot"
  type        = string
}

variable "yolo5_instance_type" {
  description = "the instance type of the specific region- for yolo5"
  type        = string
}

variable "polybot_ami_id" {
  description = "the ami id of the specific region for polybot"
  type        = string
}

variable "yolo5_ami_id" {
  description = "the ami id of the specific region for yolo5"
  type        = string
}

variable "zone_id" {
  description = "hosted zone ID"
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

variable "AWS_ACCESS_KEY_ID" {
  description = "access key id"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "secret access key"
  type        = string
}