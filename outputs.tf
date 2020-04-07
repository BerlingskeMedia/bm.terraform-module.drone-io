output "secret_key_path" {
  value = join("", aws_ssm_parameter.secret_key.*.name)
}

output "secret_key_arn" {
  value = join("", aws_ssm_parameter.secret_key.*.arn)
}

output "access_key_path" {
  value = join("", aws_ssm_parameter.access_key.*.name)
}

output "access_key_arn" {
  value = join("", aws_ssm_parameter.access_key.*.arn)
}

output "access_key_value" {
  value = join("", aws_ssm_parameter.access_key.*.value)
}