
output "project_bucket_name" {
  value = module.resources.s3_bucket_name
}

output "project_sqs_name" {
  value = module.resources.sqs_name
}

output "project_dynamodb_table_name" {
  value = module.resources.dynamodb_table_name
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