
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