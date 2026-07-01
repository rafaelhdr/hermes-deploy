# Hermes Infrastructure

This repository manages the infrastructure and configuration for deploying Hermes Agent instances on Hetzner Cloud. The deployed agent (named Samwise Gamgee) is a household grocery bot that operates over the Matrix messenger.

The stack has two layers:
- **Terraform** — provisions the cloud server and firewall on Hetzner
- **Ansible** — configures the running server: packages, GitHub auth, Python deps, config files, and systemd services

Connectivity between local and the server goes through ZeroTier (VPN). Ansible connects via the ZeroTier IP, not the public IP.

## Repository structure

```
hermes/
├── terraform/               # Cloud infrastructure (Hetzner)
│   ├── main.tf              # Server, firewall, cloud-init
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # SSH command, IPs, next steps
│   ├── cloud-init.yaml      # First-boot: ZeroTier join, hermes user, Hermes Agent install
│   └── terraform.tfvars     # Secrets (gitignored — copy from .example)
│
└── ansible/                 # Server configuration
    ├── playbook.yml         # Main playbook
    ├── inventory.yml        # Dynamic — populated from Terraform outputs at runtime
    ├── ansible.cfg          # Uses .vault_pass, disables host key checking
    ├── Justfile             # Task runner: deploy, encrypt, decrypt, edit, lint
    ├── vars/
    │   ├── main.yml         # Non-sensitive config (provider, matrix settings, paths)
    │   └── secrets.yml      # Vault-encrypted (gitignored — copy from .example)
    ├── roles/
    │   └── packages/        # System packages role
    │       └── tasks/
    │           ├── main.yml          # Imports repositories then packages
    │           ├── repositories.yml  # GitHub CLI repo, NodeSource repo
    │           └── packages.yml      # apt install: gh, libolm-dev, nodejs
    ├── templates/           # Jinja2 templates deployed to server
    │   ├── config.base.yaml.j2         # Hermes Agent configuration base (shared settings)
    │   ├── config.grocery.yaml.j2      # Grocery-specific config (includes base)
    │   ├── config.root.yaml.j2         # Root-specific config (sets app_dir + allowed_rooms, includes base)
    │   ├── .env.j2                     # Grocery gateway environment (LLM keys, Matrix creds)
    │   ├── hermes-home.env.j2          # Dashboard + root gateway environment
    │   ├── hermes-grocery-gateway.service.j2
    │   ├── hermes-root-gateway.service.j2
    │   └── hermes-dashboard.service.j2
    └── files/
        ├── AGENTS.md        # Tool instructions for the deployed grocery bot
        └── SOUL.md          # Personality definition for the deployed bot
```

## Secrets

All secrets live in `ansible/vars/secrets.yml` (Ansible Vault encrypted, gitignored). The vault password is in `ansible/.vault_pass` (also gitignored).

```bash
just edit       # decrypt → open in $EDITOR → re-encrypt
just decrypt    # decrypt in place (for inspection)
just encrypt    # re-encrypt after manual edits
```

`vars/secrets.yml.example` is the committed template. When adding a new secret, update both the example and the encrypted file.

Terraform secrets live in `terraform/terraform.tfvars` (gitignored — use `terraform.tfvars.example` as template).

## Deployment workflow

First time on a new server:

```bash
cd terraform
terraform init
terraform apply         # provisions server, runs cloud-init

# After apply: authorise the new node in the ZeroTier dashboard, then:
cd ../ansible
just deploy
```

Subsequent deploys (config or code changes only):

```bash
cd ansible
just deploy
```

Lint without connecting:

```bash
just lint
```

After a server rebuild (stale Matrix devices):

```bash
just remove-bot-devices   # cleans up orphaned Matrix sessions
just deploy
```

## What Ansible deploys

The playbook runs in this order:

1. Reads Terraform outputs → adds server as `grocery` host dynamically
2. `packages` role → sets up apt repositories (GitHub CLI, NodeSource) and installs `gh`, `libolm-dev`, `nodejs`
3. Authenticates `gh` as the `rafaelhdr-bot` GitHub App (JWT → installation token flow; skipped if already authenticated)
4. Installs Python deps into `/home/hermes/.hermes/hermes-agent/venv`
5. Builds the dashboard web frontend (`npm install && npm run build`)
6. Templates and deploys config files, `.env` files, and systemd services
7. Enables and starts `hermes-grocery-gateway`, `hermes-root-gateway`, and `hermes-dashboard`

Key paths on the server:

```
/home/hermes/hermes-grocery/     # Grocery app directory (app_dir in vars/main.yml)
├── config.yaml                  # Rendered from templates/config.yaml.j2
├── .env                         # Rendered from templates/.env.j2 (mode 0600)
├── AGENTS.md                    # Copied from ansible/files/AGENTS.md
└── SOUL.md                      # Copied from ansible/files/SOUL.md

/home/hermes/.hermes/.env        # Dashboard + root gateway env (rendered from hermes-home.env.j2)
/home/hermes/.hermes/config.yaml # Dashboard + root gateway config (config.yaml.j2, cwd=~/.hermes)
```

## LLM provider

The active provider is set in `ansible/vars/main.yml`:

```yaml
active_provider: minimax   # or: deepseek
```

Switching providers only requires changing this value and redeploying. The corresponding API key must be set in `vars/secrets.yml`.

---

## Updates

This section is for a scheduled agent that checks whether pinned versions are stale. Check each item below and open a PR if any are out of date. Do not update more than one item per PR.

### Node.js major version

**File:** `ansible/roles/packages/tasks/repositories.yml`

**Current:** NodeSource `setup_24.x` (LTS)

**How to check:** Visit https://nodejs.org/en/about/previous-releases — the current LTS major version is listed there. If it is higher than 24, update the two references in `repositories.yml`:

```yaml
cmd: curl -fsSL https://deb.nodesource.com/setup_<NEW>.x | bash -
creates: /etc/apt/sources.list.d/nodesource.list
```

Note: `creates:` uses the old path for idempotency — it will need to be cleared on the server on next deploy if the major version changes. The task that adds the new repository now runs `state: absent` on the old file before the shell command, mirroring how `github-cli.list` is cleaned up.

### Docker image for terminal backend

**File:** `ansible/templates/config.yaml.j2`

**Current:** `nikolaik/python-nodejs:python3.11-nodejs24`

**How to check:** Visit https://hub.docker.com/r/nikolaik/python-nodejs/tags and find the latest tag matching `python3.x-nodejsY`. Update the four occurrences (`docker_image`, `singularity_image`, `modal_image`, `daytona_image`) in `config.yaml.j2`.

### Terraform provider versions

**File:** `terraform/.terraform.lock.hcl`

**How to check:** From the `terraform/` directory, run:

```bash
terraform init -upgrade
```

This updates `.terraform.lock.hcl` to the latest compatible versions. Review the diff — if only patch/minor bumps, commit it. If a major version changed, check the provider changelog first.

### Python dependencies

**File:** `ansible/playbook.yml` — the `Install mautrix encryption extras` task

**Current packages:** `aiosqlite`, `asyncpg`, `fastapi`, `mautrix[encryption]`, `ptyprocess`, `uvicorn[standard]`

**How to check:** Run the following against PyPI for each package and compare with what is currently installed on the server:

```bash
pip index versions <package>
```

Or SSH into the server and run:

```bash
sudo -u hermes /home/hermes/.hermes/hermes-agent/venv/bin/pip list --outdated
```

The pip install task uses `state: present` (no version pins), so packages only update on a fresh venv. If a major version of `mautrix` is available, check its changelog before updating.

### Hermes Agent binary

**Installed by:** `terraform/cloud-init.yaml` (first-boot install script)

**How to check:** SSH into the server and run:

```bash
sudo -u hermes hermes --version
```

Then check https://github.com/nousresearch/hermes-agent/releases for the latest release. If a newer version is available, re-running the install script as `hermes` user will update it:

```bash
sudo -u hermes bash -c "$(curl -fsSL https://hermes-agent.nousresearch.com/install.sh)"
```

This does not require a full Terraform reprovisioning — it can be added as an optional Ansible task if updates become frequent.
