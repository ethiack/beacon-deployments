<a name="readme-top"></a>
<div align="center">
  <a href="https://ethiack.com">
    <img src="assets/logo.png" alt="Ethiack" height="60">
  </a>

  <h1>Ethiack Beacon - Deployment Examples</h1>

  <p>Scalable deployment templates for the Ethiack Beacon on VMs and Kubernetes clusters.</p>

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

  [Ansible](#ansible) •
  [Helm](#helm) •
  [Kubernetes YAML](#kubernetes-yaml) •
  [Configuration](#configuration) •
  [Container Image](#container-image)

</div>

---

## Overview

[Ethiack Beacon](https://ethiack.com) is a lightweight secure tunnel that gives the Ethiack Hackian Engine secure access to your internal networks - no inbound firewall rules or port-forwarding required.

This repository contains ready-to-use templates for deploying beacons at scale across fleets of VMs or Kubernetes clusters.

> **Single machine?** Use the interactive install script instead:
> ```bash
> curl -fsSL https://portal.ethiack.com/scripts/beacon/install | sudo bash
> ```

### Deployment methods

| Method | Best for | Folder |
|--------|----------|--------|
| [**Ansible**](#ansible) | Linux VMs - EC2, on-prem, bare-metal | [`ansible/`](ansible/) |
| [**Helm**](#helm) | Kubernetes with Helm | [`helm/ethiack-beacon/`](helm/ethiack-beacon/) |
| [**Kubernetes YAML**](#kubernetes-yaml) | Kubernetes without Helm | [`kubernetes/`](kubernetes/) |

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## Ansible

Deploys the beacon as a Docker Compose service on Linux VMs. Tested on Ubuntu 20.04/22.04/24.04, Debian 11/12, Amazon Linux 2/2023, and RHEL/CentOS 8+.

**Prerequisites:** Ansible 2.12+, SSH access to target hosts, internet access on targets.

```bash
# 1. Install required collections
ansible-galaxy collection install -r ansible/requirements.yml

# 2. Create and edit your inventory
cp ansible/inventory.example.yml ansible/inventory.yml

# 3. Set credentials in ansible/group_vars/all.yml (use Ansible Vault for
#    production). Exported shell variables are NOT read by the role.

# 4. Deploy
ansible-playbook -i ansible/inventory.yml ansible/site.yml

# Alternatively, skip step 3 for a quick test and pass the key inline. Use one
# or the other: extra-vars outrank group_vars and would override a vaulted value.
ansible-playbook -i ansible/inventory.yml ansible/site.yml \
  -e ethiack_api_key=phx_your_api_key
```

See [`ansible/README.md`](ansible/README.md) for full variable reference, multi-VPC setup, and Ansible Vault instructions.

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## Helm

```bash
helm install ethiack-beacon ./helm/ethiack-beacon \
  --set credentials.apiKey=phx_your_api_key \
  --set beacon.name=prod-cluster \
  --set beacon.cidrs="10.0.0.0/8\,172.16.0.0/12"
```

Legacy (non-`phx_`) keys additionally set `--set credentials.apiSecret=your_api_secret`.

Or use a `values.yaml`:

```yaml
credentials:
  apiKey: phx_your_api_key
  # Legacy (non-phx_) keys only:
  # apiSecret: your_api_secret
beacon:
  name: prod-cluster
  cidrs: "10.0.0.0/8,172.16.0.0/12"
```

```bash
helm install ethiack-beacon ./helm/ethiack-beacon -f values.yaml
```

See [`helm/ethiack-beacon/`](helm/ethiack-beacon/) for the full chart and values reference.

### Upgrading to chart 0.2.0

Chart 0.2.0 makes `credentials.apiSecret` optional (only legacy, non-`phx_` keys
need it) and renders the credentials Secret as `data` instead of `stringData`.
Upgrading in place with both values still set is a no-op change - nothing to do.

If you are **rotating a legacy key:secret pair to a `phx_` key** on a release
first installed with chart 0.1.0, clearing `credentials.apiSecret` leaves the old
`ETHIACK_API_SECRET` orphaned in the live Secret: it is named under `stringData`
in that release's stored manifest, so Helm computes no deletion for it. The
beacon ignores it - the CLI picks its auth scheme from the key prefix and never
sends two credentials - but to clear the stale value, delete the Secret once and
re-run the upgrade:

```bash
kubectl -n <namespace> delete secret <release>-ethiack-beacon-credentials
helm upgrade <release> ./helm/ethiack-beacon --set credentials.apiKey=phx_your_api_key ...
```

Releases installed on 0.2.0 or later do not need this - clearing
`credentials.apiSecret` removes the key on the next upgrade.

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## Kubernetes YAML

```bash
# 1. Base64-encode your API key
echo -n 'YOUR_API_KEY'    | base64
echo -n 'YOUR_API_SECRET' | base64   # legacy (non-phx_) keys only

# 2. Edit secret.yaml with the encoded values
# 3. Edit deployment.yaml - set ETHIACK_BEACON_NAME and ETHIACK_BEACON_CIDRS

# 4. Apply
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/deployment.yaml

# 5. Verify
kubectl -n ethiack get pods
kubectl -n ethiack logs -f deployment/ethiack-beacon
```

See [`kubernetes/README.md`](kubernetes/README.md) for notes on host networking, capabilities, and lifecycle hooks.

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## Configuration

### Required

| Variable | Description |
|----------|-------------|
| `ETHIACK_API_KEY` | API key - from the [Ethiack Portal](https://portal.ethiack.com). A `phx_`-prefixed key authenticates as `Authorization: Bearer` and has no secret |
| `ETHIACK_BEACON_NAME` | Unique name for this beacon |
| `ETHIACK_BEACON_CIDRS` | Comma-separated CIDRs to expose, e.g. `10.0.0.0/8,192.168.1.0/24` |

### Legacy credentials

| Variable | Description |
|----------|-------------|
| `ETHIACK_API_SECRET` | API secret - required only for legacy (non-`phx_`) keys, which are sent as HTTP Basic. Do not set it alongside a `phx_` key |

### CIDR auto-detection

Set `ETHIACK_ASSUME_DETECTED_CIDRS=1` to let the beacon detect CIDRs automatically from the host's network interfaces. When set, `ETHIACK_BEACON_CIDRS` is not required - useful for Kubernetes nodes where you want to expose whatever networks the node can see.

### Pentest scope

| Variable | Default | Description |
|----------|---------|-------------|
| `ETHIACK_CREATE_PENTEST` | `true` | Automatically create a new pentest and add the beacon's CIDRs to its scope |
| `ETHIACK_PENTEST_SLUG` | - | Add the beacon's CIDRs to an existing pentest's scope (overrides `ETHIACK_CREATE_PENTEST`) |
| `ETHIACK_SKIP_PENTEST_CONFIG` | - | Set to `1` to skip all pentest configuration entirely |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `ETHIACK_API_URL` | `https://api.ethiack.com` | API base URL |
| `ETHIACK_BEACON_HEALTH_INTERVAL` | `300` | Health report interval in seconds |
| `ETHIACK_ORG_ID` | auto-detected | Organization ID (set explicitly if your key has access to multiple orgs) |

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## Container Image

```
europe-docker.pkg.dev/ethiack/public/beacon:latest
```

Public, multi-arch image (amd64 + arm64). The beacon runs and requires elevated Linux capabilities:

```yaml
# Kubernetes securityContext
capabilities:
  add:
    - NET_ADMIN
    - SYS_MODULE
```

It also requires host networking (`hostNetwork: true`) and read access to `/lib/modules`.

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>

---

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

<p align="right"><small>(<a href="#readme-top">back to top</a>)</small></p>
