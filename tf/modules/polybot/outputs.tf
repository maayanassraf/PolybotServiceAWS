
output "polybot_instance_type" {
  value = data.aws_ec2_instance_types.polybot_instance_types.instance_types[0]
}

output "project_telegram_token_secret_id" {
  value = aws_secretsmanager_secret.tf-botToken.id
}

output "project_telegram_app_url" {
  value = aws_route53_record.alb_record.fqdn
}

output "project_telegram_app_url_port_https" {
  value = aws_lb_listener.alb_https.port
}

output "project_telegram_app_url_port_http" {
  value = aws_lb_listener.alb_http.port
}