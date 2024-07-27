resource "aws_secretsmanager_secret" "tf-botToken" {
  name = "tf-telegram-botToken"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tf-botToken-value" {
  secret_id     = aws_secretsmanager_secret.tf-botToken.id
  secret_string = var.botToken
}