output "s3_bucket_arn" {
  value = aws_s3_bucket.tf-images-bucket.arn
}

output "sqs_arn" {
  value = aws_sqs_queue.tf-project-queue.arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.tf-predictions-dynamodb-table.arn
}