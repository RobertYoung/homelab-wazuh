# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-host Ansible project for managing a Wazuh server in a home lab environment. The inventory contains only one host: `wazuh-server` at `wazuh.local.iamrobertyoung.co.uk`.

## Key Commands

All commands require AWS credentials via aws-vault for SSM parameter lookups.

### Test connectivity
```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible wazuh -m ping
```

### Run the main playbook
```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml
```

### Install external role dependencies
```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml
```

### Create a new custom role
```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy init roles/role_name
```

## Architecture

### Single-Environment Setup
Unlike typical Ansible projects with multiple environments (dev/staging/prod), this is a home lab with:
- Single inventory file at `inventories/hosts.yml`
- Single host group `wazuh` containing one server
- No environment subdirectories under `inventories/`

### Configuration Hierarchy
1. `ansible.cfg` - Project defaults (uses `inventories/hosts.yml` by default)
2. `group_vars/wazuh.yml` - Variables applied to all hosts in the `wazuh` group
3. `host_vars/` - Host-specific variables (if needed)
4. `inventories/hosts.yml` - Single host definition

### Ansible Configuration Notes
- Output format: Uses `result_format = yaml` with `stdout_callback = default` (modern Ansible 2.13+ approach)
- Privilege escalation enabled by default (become = True)
- Host key checking disabled for home lab convenience
- SSH pipelining enabled for performance

### Tool Versions
Tool versions are managed via mise and frozen in `mise.toml`:
- ansible 13.1.0
- pipx 1.8.0
- uv 0.9.18

When adding new playbooks or roles, target the single `wazuh` host group in playbook definitions.
