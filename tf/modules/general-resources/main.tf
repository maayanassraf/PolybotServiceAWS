resource "aws_s3_bucket" "tf-images-bucket" {
  bucket = "tf-${var.owner}-images-bucket-${var.region}"
  tags = {
    Name        = "tf-${var.owner}-images-bucket-${var.region}"
    Env         = var.env
    Terraform   = true
  }
  force_destroy = true
}

resource "aws_dynamodb_table" "tf-predictions-dynamodb-table" {
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

resource "aws_sqs_queue" "tf-project-queue" {
  name                      = "tf-${var.owner}-project-queue"
  message_retention_seconds = 86400
  sqs_managed_sse_enabled = true

  tags = {
    Environment = var.env
  }
}