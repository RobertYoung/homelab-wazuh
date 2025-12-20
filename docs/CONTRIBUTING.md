# Contributing Guide

## Conventional Commits

This project uses [Conventional Commits](https://www.conventionalcommits.org/) to automate versioning and changelog generation through semantic-release.

### Commit Message Format

Each commit message should follow this structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

The following commit types will trigger releases:

| Type | Release | Description | Example |
|------|---------|-------------|---------|
| `feat` | Minor (0.x.0) | A new feature | `feat: add wazuh agent configuration role` |
| `fix` | Patch (0.0.x) | A bug fix | `fix: correct firewall rules for wazuh manager` |
| `perf` | Patch (0.0.x) | Performance improvement | `perf: optimize task execution with async` |
| `revert` | Patch (0.0.x) | Revert a previous commit | `revert: undo changes to ssh configuration` |
| `docs` | Patch (0.0.x) | Documentation changes | `docs: update README with new requirements` |
| `refactor` | Patch (0.0.x) | Code refactoring | `refactor: simplify variable structure` |

The following types will NOT trigger releases:

| Type | Description | Example |
|------|-------------|---------|
| `chore` | Maintenance tasks | `chore: update ansible-lint configuration` |
| `test` | Test changes | `test: add molecule tests for wazuh role` |
| `build` | Build system changes | `build: update mise tool versions` |
| `ci` | CI/CD changes | `ci: add ansible-lint to GitHub Actions` |

### Breaking Changes

To trigger a major version release (x.0.0), add `BREAKING CHANGE:` in the commit footer or use `!` after the type:

```
feat!: migrate to wazuh 4.x

BREAKING CHANGE: Wazuh 3.x is no longer supported. Update your configuration to use Wazuh 4.x API endpoints.
```

### Examples

#### Feature Addition
```
feat(monitoring): add email alerting configuration

Configure SMTP settings for Wazuh alerts with customizable templates.
Supports TLS encryption and authentication.

Closes #42
```

#### Bug Fix
```
fix(firewall): open required ports for agent communication

Added missing UDP port 1514 to allow syslog communication from agents.
```

#### Documentation Update
```
docs: add troubleshooting section to README

Include common SSH connection issues and solutions.
```

#### Breaking Change
```
feat(inventory)!: change inventory structure to dynamic inventory

BREAKING CHANGE: Static inventory file replaced with dynamic inventory script.
Users must update their inventory configuration.
```

### Scopes

Common scopes for this project:

- `monitoring` - Wazuh monitoring and alerting
- `firewall` - Firewall and security rules
- `config` - Configuration management
- `inventory` - Inventory and host management
- `roles` - Ansible roles
- `playbooks` - Playbook changes
- `deps` - Dependency updates

### Skipping Releases

To prevent a commit from triggering any analysis (useful for CI commits), add `[skip ci]` to the commit message:

```
chore: update changelog [skip ci]
```

## Pull Request Guidelines

1. Use conventional commit format for PR titles
2. Squash commits when merging to maintain clean history
3. Ensure all CI checks pass before merging
4. Include tests for new features when applicable

## Release Process

Releases are fully automated:

1. Commit changes using conventional commit format
2. Push to `main` branch
3. GitHub Actions runs semantic-release
4. semantic-release analyzes commits and determines version
5. Changelog is generated and committed
6. GitHub release is created with release notes
7. Version tag is created

## Local Testing

Before pushing commits, you can validate commit messages locally:

```bash
# Install commitlint (optional)
npm install --save-dev @commitlint/cli @commitlint/config-conventional

# Validate last commit
npx commitlint --from HEAD~1 --to HEAD --verbose
```

## Security Best Practices

Our GitHub Actions workflows follow security best practices from [StepSecurity](https://www.stepsecurity.io/blog/github-actions-security-best-practices):

### Actions Pinning
- **All GitHub Actions are pinned to commit SHAs** instead of version tags for immutability
- Comments include the version tag for readability (e.g., `# v4.1.7`)
- This prevents supply chain attacks from compromised action updates

### Runtime Security
- **Harden-Runner** is used to restrict egress network traffic
- Initially runs in audit mode to identify legitimate traffic patterns
- Can be switched to block mode after traffic patterns are understood

### Least Privilege
- **Minimal permissions** by default at workflow and job levels
- Permissions explicitly granted only where needed
- Default `GITHUB_TOKEN` has read-only access

### Workflow Updates
- Actions are updated via Dependabot (configured separately)
- All workflow changes require peer review via branch protection
- Changes to `.github/workflows/` should be reviewed carefully

## Questions?

If you're unsure about commit message formatting, refer to:
- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
