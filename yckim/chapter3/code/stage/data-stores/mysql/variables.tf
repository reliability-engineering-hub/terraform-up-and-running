data "aws_secretmanager_secret_version" "db_password" {
	secret_id = "mysql-master-password-stage"
}