resource "aws_secretsmanager_secret" "tf-botToken" {
  name = "tf-telegram-botToken-${var.region}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tf-botToken-value" {
  secret_id     = aws_secretsmanager_secret.tf-botToken.id
  secret_string = var.botToken
}