data "aws_secretsmanager_secret" "db_password" {
  name = "prod/plusone/db_password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

data "aws_secretsmanager_secret" "db_user" {
  name = "prod/plusone/db_user_name"
}

data "aws_secretsmanager_secret_version" "db_user" {
  secret_id = data.aws_secretsmanager_secret.db_user.id
}

data "aws_secretsmanager_secret" "secret_key_base" {
  name = "prod/plusone/secret_key_base"
}

data "aws_secretsmanager_secret_version" "secret_key_base" {
  secret_id = data.aws_secretsmanager_secret.secret_key_base.id
}

data "aws_secretsmanager_secret" "cognito_user_pool_id" {
  name = "prod/plusone/cognito_user_pool_id"
}

data "aws_secretsmanager_secret_version" "cognito_user_pool_id" {
  secret_id = data.aws_secretsmanager_secret.cognito_user_pool_id.id
}

data "aws_secretsmanager_secret" "cognito_app_client_id" {
  name = "prod/plusone/cognito_app_client_id"
}

data "aws_secretsmanager_secret_version" "cognito_app_client_id" {
  secret_id = data.aws_secretsmanager_secret.cognito_app_client_id.id
}