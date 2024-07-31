output "s3_bucket_arn" {
  value = aws_s3_bucket.tf-images-bucket.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.tf-images-bucket.bucket
}

output "sqs_arn" {
  value = aws_sqs_queue.tf-project-queue.arn
}

output "sqs_name" {
  value = aws_sqs_queue.tf-project-queue.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.tf-predictions-dynamodb-table.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf-predictions-dynamodb-table.name
}