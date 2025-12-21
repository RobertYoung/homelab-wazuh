output "wazuh_indexer_password_arn" {
  description = "ARN of the Wazuh indexer password SSM parameter"
  value       = aws_ssm_parameter.wazuh_indexer_password.arn
}

output "wazuh_indexer_password_name" {
  description = "Name of the Wazuh indexer password SSM parameter"
  value       = aws_ssm_parameter.wazuh_indexer_password.name
}

output "wazuh_indexer_password" {
  description = "Generated password for Wazuh indexer (use 'terraform output -raw wazuh_indexer_password' to view)"
  value       = random_password.wazuh_indexer_password.result
  sensitive   = true
}

output "wazuh_api_password_arn" {
  description = "ARN of the Wazuh API password SSM parameter"
  value       = aws_ssm_parameter.wazuh_api_password.arn
}

output "wazuh_api_password_name" {
  description = "Name of the Wazuh API password SSM parameter"
  value       = aws_ssm_parameter.wazuh_api_password.name
}

output "wazuh_api_password" {
  description = "Generated password for Wazuh API (use 'terraform output -raw wazuh_api_password' to view)"
  value       = random_password.wazuh_api_password.result
  sensitive   = true
}
