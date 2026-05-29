# Hermes

A home for [Hermes Agent](https://github.com/NousResearch/hermes-agent) deployments — infrastructure, config, and personalities managed as code.

This project provisions a server and deploys Hermes agents with their configuration, system prompts, and gateway services. The first agent is a grocery-list bot (Samwise Gamgee), used as a starting point to learn how Hermes works.

More agents and roles to come.

- **Terraform** provisions the Hetzner Cloud server, firewall, SSH key, and bootstraps the Hermes Agent.
- **Ansible** deploys agent config, system prompts, secrets, and the systemd gateway service.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ 1.0
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [just](https://github.com/casey/just) (command runner)
- A [Hetzner Cloud](https://www.hetzner.com/cloud) account with an API token
- An SSH key registered in your Hetzner account
- A Matrix account for the bot

## Quick start

```bash
# 1. Provision the server
cd terraform
cp terraform.tfvars.example terraform.tfvars    # fill in your values
terraform init
terraform apply

# 2. Deploy the agent
cd ../ansible
cp vars/secrets.yml.example vars/secrets.yml    # fill in secrets
uv sync
echo "your-vault-passphrase" > .vault_pass
just encrypt                                    # encrypt secrets
just deploy
```

## Terraform

Provisions a single Hetzner Cloud server running Ubuntu 24.04 with the Hermes Agent installed. A non-root `hermes` user is created with passwordless sudo and your SSH key.

### Variables (`terraform.tfvars`)

| Variable              | Required | Description                           |
|-----------------------|----------|---------------------------------------|
| `hcloud_token`        | yes      | Hetzner Cloud API token               |
| `ssh_key_fingerprint` | yes      | SSH key fingerprint in Hetzner        |
| `cluster_name`        | no       | Name prefix (default: `hermes`)       |
| `server_type`         | no       | Server type (default: `cpx22`)        |
| `location`            | no       | Datacenter (default: `fsn1`)          |
| `os_image`            | no       | OS image (default: `ubuntu-24.04`)    |

## Ansible

Deploys agent configuration to the server. The playbook reads the server IP dynamically from `terraform output` — nothing is hardcoded.

### Secrets (`vars/secrets.yml`)

| Variable              | Description                               |
|-----------------------|-------------------------------------------|
| `deepseek_api_key`    | DeepSeek API key                          |
| `matrix_password`     | Matrix account password (for token gen)   |
| `matrix_recovery_key` | Matrix encryption recovery key            |
| `matrix_home_room`    | Matrix room ID where the bot lives        |
| `matrix_user_id`      | Matrix user ID for the bot                |
| `matrix_allowed_users`| Matrix users allowed to interact          |
| `matrix_access_token` | Optional — use instead of password login  |

### Non-sensitive config (`vars/main.yml`)

| Variable                  | Default                                                    |
|---------------------------|------------------------------------------------------------|
| `app_dir`                 | `/home/hermes/hermes-grocery`                              |
| `hermes_bin`              | `/home/hermes/.hermes/hermes-agent/venv/bin/hermes`        |
| `matrix_homeserver`       | `https://matrix.org`                                       |

### Workflow

```bash
cd ansible
just help       # show available commands
just edit       # edit encrypted secrets
just deploy     # apply configuration to the server
just lint       # syntax-check the playbook
```

The playbook:
1. Fetches the server IP from Terraform state
2. Copies `config.yaml`, `AGENTS.md`, and `SOUL.md` to the server
3. Logs into Matrix with the bot password to obtain an access token
4. Templates the `.env` file with resolved secrets
5. Deploys and starts the systemd gateway service

## Agents

### Grocery (Samwise Gamgee)

Manages a household grocery list over Matrix. The list lives at `~/hermes-grocery/grocery.md`.

- `AGENTS.md` — tool instructions: read/write the grocery file
- `SOUL.md` — personality: a warm, hard-working hobbit grocer
- Gateway: `hermes-grocery-gateway.service`

## Files on the server

```
/home/hermes/hermes-grocery/
├── config.yaml          # Hermes Agent configuration
├── .env                 # Environment secrets (0600)
├── AGENTS.md            # Agent tool instructions
├── SOUL.md              # Bot personality
└── grocery.md           # The grocery list (created by the agent)
```

## Project layout

```
hermes/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf                # Server, firewall, SSH key
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Terraform outputs
│   ├── cloud-init.yaml        # First-boot provisioning
│   └── terraform.tfvars.example
├── ansible/                   # Configuration management
│   ├── playbook.yml           # Main playbook
│   ├── inventory.yml          # Dynamic inventory
│   ├── ansible.cfg            # Ansible configuration
│   ├── pyproject.toml         # Python dependencies (uv)
│   ├── uv.lock                # Pinned dependency versions
│   ├── Justfile               # Task runner
│   ├── .vault_pass            # Ansible Vault passphrase (gitignored)
│   ├── files/
│   │   ├── config.yaml        # Hermes config
│   │   ├── AGENTS.md          # First agent system prompt
│   │   └── SOUL.md            # First agent personality
│   ├── templates/
│   │   ├── .env.j2            # Environment template
│   │   └── hermes-grocery-gateway.service.j2
│   └── vars/
│       ├── main.yml           # Non-sensitive variables
│       ├── secrets.yml        # Encrypted secrets (gitignored)
│       └── secrets.yml.example
└── README.md
```
