data "aws_ssm_parameter" "database_password" {
  name = "${local.ssm_path_database}"
}

data "aws_ssm_parameter" "database_username" {
  name = "${local.ssm_path_database}/username"
}