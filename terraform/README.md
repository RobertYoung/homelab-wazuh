# Wazuh Terraform Configuration

This Terraform configuration automatically generates secure random passwords and stores them in AWS SSM Parameter Store for Wazuh authentication.

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- aws-vault (recommended for credential management)

## What This Creates

This Terraform configuration automatically:

1. **Generates two secure random passwords** (32 characters each)

   - One for Wazuh indexer admin user
   - One for Wazuh API (dashboard-to-manager communication)

2. **Creates two AWS SSM SecureString parameters** with the generated passwords:
   - `/home-server/wazuh-indexer-password`
   - `/home-server/wazuh-api-password`

**No manual password input required!** Terraform generates cryptographically secure passwords automatically.

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform init
```

### 2. Create the SSM Parameters

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform apply
```

Review the plan and type `yes` to confirm. Terraform will generate random passwords and create the SSM parameters.

### 3. View Generated Passwords

After applying, you can view the generated passwords:

```bash
# View the indexer password
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform output -raw wazuh_indexer_password

# View the API password
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform output -raw wazuh_api_password
```

**Note:** These passwords are also stored in the Terraform state file, so keep it secure!

## Usage

### Plan Changes

Preview what Terraform will create/update:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform plan
```

### Apply Configuration

Create or update the SSM parameters:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform apply
```

### View All Outputs

Display parameter ARNs, names, and passwords:

```bash
# View all outputs (passwords will be hidden)
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform output

# View specific password
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform output -raw wazuh_indexer_password
```

### View Current State

See what resources Terraform is managing:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform show
```

## Password Rotation

To rotate passwords (generate new random passwords):

```bash
# Taint the random password resources to force regeneration
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform taint random_password.wazuh_indexer_password

aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform taint random_password.wazuh_api_password

# Apply to generate new passwords
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform apply

# Re-run the Ansible playbook to update Wazuh with new passwords
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  ansible-playbook playbooks/site.yml --tags wazuh
```

## Retrieving Passwords Later

You can retrieve passwords at any time using:

**From Terraform state:**

```bash
cd terraform
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  terraform output -raw wazuh_indexer_password
```

**From AWS SSM directly:**

```bash
# Get indexer password
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  aws ssm get-parameter --name /home-server/wazuh-indexer-password \
  --with-decryption --query 'Parameter.Value' --output text

# Get API password
aws-vault exec iamrobertyoung:home-assistant-production:p -- \
  aws ssm get-parameter --name /home-server/wazuh-api-password \
  --with-decryption --query 'Parameter.Value' --output text
```

## Configuration

All configuration is hardcoded in the Terraform files for simplicity:

- **AWS Region**: `eu-west-1`
- **SSM Parameter Prefix**: `/home-server`
- **Password Length**: 32 characters
- **Special Characters**: `!@#$%^&*()-_=+[]{}:?`

To change these values, edit the Terraform files directly:

- `versions.tf` - AWS region
- `main.tf` - Password length, SSM parameter names, special characters

## Security Notes

- **Automatic Generation**: Passwords are cryptographically secure random strings (32 characters with special characters)
- **Secure Storage**: Passwords stored as SecureString in AWS SSM Parameter Store (encrypted with AWS KMS)
- **Sensitive Outputs**: Password outputs are marked sensitive and masked in Terraform output
- **State File Security**: Terraform state contains the passwords - keep `terraform.tfstate` secure and never commit to version control
- **Character Set**: Generated passwords use alphanumeric and safe special characters: `!@#$%^&*()-_=+[]{}:?`

## Files

- **versions.tf** - Terraform and provider version constraints (AWS ~> 6.0, Random ~> 3.6)
- **main.tf** - Random password generation and SSM parameter resources
- **outputs.tf** - Resource outputs (ARNs, names, and sensitive passwords)
- **README.md** - This file

## Troubleshooting

### Authentication Errors

Ensure you're using aws-vault with the correct profile:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform plan
```

### Permission Errors

Ensure your AWS credentials have permissions to:

- Create/update SSM parameters
- Use KMS keys for SecureString encryption
- Tag resources

### Lost Passwords

If you lose access to passwords:

1. They're stored in Terraform state: `terraform output -raw wazuh_indexer_password`
2. They're in AWS SSM: `aws ssm get-parameter --name /home-server/wazuh-indexer-password --with-decryption`
3. As a last resort, taint and regenerate (requires Wazuh redeployment)

### State File Management

The Terraform state file (`terraform.tfstate`) contains:

- Resource metadata (ARNs, IDs)
- **The actual generated passwords** (in plaintext within the state)

**Important:** Keep the state file secure! Consider using remote state with encryption for production.

## Cleanup

To remove all resources:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- terraform destroy
```

**Warning:** This deletes the SSM parameters. Retrieve passwords first if you need them:

```bash
terraform output -raw wazuh_indexer_password > indexer_password.txt
terraform output -raw wazuh_api_password > api_password.txt
```

## Integration with Ansible

After running `terraform apply`, the passwords are automatically available to Ansible via AWS SSM lookups in `group_vars/wazuh.yml`:

```yaml
wazuh_indexer_password: "{{ lookup('amazon.aws.aws_ssm', '/home-server/wazuh-indexer-password') }}"
wazuh_api_password: "{{ lookup('amazon.aws.aws_ssm', '/home-server/wazuh-api-password') }}"
```

No additional configuration needed!
