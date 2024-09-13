/*data "aws_ssm_parameter" "database_password" {
  name = local.ssm_path_database
  depends_on = aws_ssm_parameter.database_password
}

data "aws_ssm_parameter" "database_username" {
  name = "${local.ssm_path_database}/username"
  depends_on = aws_ssm_parameter.database_username
}*/