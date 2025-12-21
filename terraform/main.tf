# Generate random password for Wazuh Indexer
resource "random_password" "wazuh_indexer_password" {
  length  = 32
  special = true
  # Ensure compatibility with Wazuh by avoiding problematic special characters
  override_special = "!@#$%^&*()-_=+[]{}:?"
}

# Generate random password for Wazuh API
resource "random_password" "wazuh_api_password" {
  length  = 32
  special = true
  # Ensure compatibility with Wazuh by avoiding problematic special characters
  override_special = "!@#$%^&*()-_=+[]{}:?"
}

# Generate random password for Kibana
resource "random_password" "wazuh_kibana_password" {
  length  = 32
  special = true
  # Ensure compatibility with Wazuh by avoiding problematic special characters
  override_special = "!@#$%^&*()-_=+[]{}:?"
}

# Wazuh Indexer Password
# Used by the indexer service for authentication
resource "aws_ssm_parameter" "wazuh_indexer_password" {
  name        = "/home-server/wazuh-indexer-password"
  description = "Password for Wazuh indexer admin user"
  type        = "SecureString"
  value       = random_password.wazuh_indexer_password.result

  tags = {
    Component = "wazuh-indexer"
    Purpose   = "authentication"
  }
}

# Wazuh API Password
# Used by the dashboard to communicate with the Wazuh manager API
resource "aws_ssm_parameter" "wazuh_api_password" {
  name        = "/home-server/wazuh-api-password"
  description = "Password for Wazuh API wazuh-wui user"
  type        = "SecureString"
  value       = random_password.wazuh_api_password.result

  tags = {
    Component = "wazuh-api"
    Purpose   = "authentication"
  }
}

# Kibana Password
# Used by the Wazuh dashboard (kibanaserver user) for authentication with the indexer
resource "aws_ssm_parameter" "wazuh_kibana_password" {
  name        = "/home-server/wazuh-kibana-password"
  description = "Password for Wazuh dashboard kibanaserver user"
  type        = "SecureString"
  value       = random_password.wazuh_kibana_password.result

  tags = {
    Component = "wazuh-dashboard"
    Purpose   = "authentication"
  }
}
