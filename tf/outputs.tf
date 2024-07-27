output "launch_template_id" {
  value = module.yolo5.launch_template_id
}

output "project_bucket_name" {
  value = aws_s3_bucket.tf-maayana-images-bucket.bucket
}

output "project_sqs_name" {
  value = aws_sqs_queue.tf-maayana-project-queue.name
}

output "project_dynamodb_table_name" {
  value = aws_dynamodb_table.tf-maayana-predictions-dynamodb-table.name
}

output "project_telegram_token_secret_id" {
  value = module.polybot.project_telegram_token_secret_id
}

output "project_telegram_app_url" {
  value = module.polybot.project_telegram_app_url
}

output "project_telegram_app_url_port_https" {
  value = module.polybot.project_telegram_app_url_port_https
}

output "project_telegram_app_url_port_http" {
  value = module.polybot.project_telegram_app_url_port_http
}