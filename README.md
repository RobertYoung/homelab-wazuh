# Homelab Wazuh Ansible Project

This Ansible project manages a Wazuh server installation for a home lab environment.

## Project Structure

```
.
├── ansible.cfg                          # Ansible configuration
├── inventories/
│   └── hosts.yml                        # Inventory file with Wazuh host
├── group_vars/
│   └── wazuh.yml                        # Variables for Wazuh group
├── host_vars/                           # Host-specific variables
├── roles/                               # Custom Ansible roles
├── playbooks/
│   └── site.yml                         # Main playbook
├── files/                               # Static files to copy to hosts
├── templates/                           # Jinja2 templates
└── requirements.yml                     # External role dependencies
```

## Prerequisites

- Ansible installed on your control machine
- SSH access to the Wazuh server
- Python installed on the target host
- AWS credentials configured via aws-vault for SSM parameter access (region eu-west-2 is specified in playbook)

## Configuration

1. Edit `inventories/hosts.yml` to set your Wazuh server's IP address and SSH user
2. Update `group_vars/wazuh.yml` with your Wazuh-specific configuration
3. Add any host-specific variables in `host_vars/`

## Usage

All commands must be run with AWS credentials via aws-vault for SSM parameter access.

### Run the main playbook

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml
```

### Run with specific inventory

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook -i inventories/hosts.yml playbooks/site.yml
```

### Check connectivity

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible wazuh -m ping
```

### Install external roles

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml
```

## Adding Roles

To add a new role:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy init roles/role_name
```

Or add external roles to `requirements.yml` and install them with:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml
```
