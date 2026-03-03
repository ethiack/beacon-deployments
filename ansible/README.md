# Ansible deployment

Deploys the Ethiack Beacon as a Docker Compose service on Linux VMs.

Tested on: Ubuntu 20.04/22.04/24.04, Debian 11/12, Amazon Linux 2/2023, RHEL/CentOS 8+.

## Prerequisites

- Ansible 2.12+
- Target hosts must be reachable via SSH
- Target hosts need internet access to pull the beacon image

## Quick start

1. Install required collections:
   ```bash
   ansible-galaxy collection install -r deploy/ansible/requirements.yml
   ```

2. Copy and edit the inventory:
   ```bash
   cp inventory.example.yml inventory.yml
   # edit inventory.yml with your host IPs / SSH settings
   ```

3. Set credentials (use Ansible Vault for production):
   ```bash
   # Quick test (plain text):
   export ETHIACK_API_KEY=your_api_key
   export ETHIACK_API_SECRET=your_api_secret

   # Production (vault-encrypted):
   ansible-vault encrypt_string 'your_api_key'    --name 'ethiack_api_key'
   ansible-vault encrypt_string 'your_api_secret' --name 'ethiack_api_secret'
   # Paste the output into group_vars/all.yml
   ```

4. Edit `group_vars/all.yml` with your beacon name and CIDRs.

5. Run:
   ```bash
   ansible-playbook -i inventory.yml site.yml
   # With vault:
   ansible-playbook -i inventory.yml site.yml --ask-vault-pass
   ```

## Variables

All variables are defined in `roles/ethiack-beacon/defaults/main.yml`.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ethiack_api_key` | yes | - | Ethiack API key |
| `ethiack_api_secret` | yes | - | Ethiack API secret |
| `ethiack_beacon_name` | yes | `{{ inventory_hostname }}` | Beacon identifier |
| `ethiack_beacon_cidrs` | yes | - | CIDRs to expose, e.g. `10.0.0.0/8` |
| `ethiack_api_url` | no | `https://api.ethiack.com` | API base URL |
| `ethiack_beacon_health_interval` | no | `300` | Health reporting interval (seconds) |
| `ethiack_pentest_slug` | no | `""` | Pentest slug to associate CIDRs with |
| `ethiack_beacon_image` | no | `europe-docker.pkg.dev/ethiack/public/beacon:latest` | Container image |
| `ethiack_beacon_install_dir` | no | `~/ethiack-beacon` | Directory for compose files on target |

## Multiple VPCs / hosts

Add each host to the `[beacon_hosts]` group. Each gets its own beacon with its own `ethiack_beacon_name`. Use `host_vars/<hostname>.yml` to override per-host variables:

```yaml
# host_vars/prod-vpc-a.example.com.yml
ethiack_beacon_name: prod-vpc-a
ethiack_beacon_cidrs: "10.10.0.0/16"
```

## Updating CIDRs

Change `ethiack_beacon_cidrs` in your inventory or `group_vars/all.yml`, then re-run `site.yml`. The role restarts the container, and the entrypoint automatically calls `beacon update --cidrs` before the health loop resumes.

## Deleting a beacon

Run the dedicated delete playbook. It deregisters the beacon from the Ethiack portal, stops the Docker Compose stack, and removes the data volume:

```bash
ansible-playbook -i inventory.yml deploy/ansible/delete.yml
```

To also remove the install directory on the target host:

```bash
ansible-playbook -i inventory.yml deploy/ansible/delete.yml \
  -e ethiack_beacon_remove_install_dir=true
```

## Windows

Docker Desktop with WSL2 (Linux container backend) is required. Ensure WinRM is configured for Ansible connectivity and that Docker is running before executing the playbook. The role tasks target Linux package managers - override the `ethiack_beacon_docker_install` variable to `false` if Docker is already present.
