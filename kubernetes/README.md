# Kubernetes - raw YAML deployment

Use these manifests with `kubectl apply` if you prefer not to use Helm.

## Quick start

1. Edit `secret.yaml` - replace the placeholder values with your base64-encoded credentials:
   ```bash
   echo -n 'YOUR_API_KEY'    | base64
   echo -n 'YOUR_API_SECRET' | base64
   ```

2. Edit `deployment.yaml` - set `ETHIACK_BEACON_NAME` and `ETHIACK_BEACON_CIDRS`.

3. Apply:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f pvc.yaml
   kubectl apply -f deployment.yaml
   ```

4. Check status:
   ```bash
   kubectl -n ethiack get pods
   kubectl -n ethiack logs -f deployment/ethiack-beacon
   ```

## Notes

- **One beacon per VPC.** Deploy in one namespace per cluster. If you have multiple clusters in different VPCs, deploy this in each.
- **`hostNetwork: true`** is required - the beacon binds a WireGuard UDP port on the node's IP and needs to see the node's network interfaces.
- **`NET_ADMIN` + `SYS_MODULE`** capabilities are required for WireGuard to create the `wg0` interface and load kernel modules.
- **`Recreate` strategy** ensures the old pod releases the WireGuard interface before the new one starts.
- The PVC persists beacon state across pod restarts so the beacon doesn't re-register on every restart.
- **hostPath alternative**: if you prefer the state to live in a directory on the node (e.g. `~/ethiack-beacon`), replace the PVC volume in `deployment.yaml` with the commented `hostPath` block. You can then skip `pvc.yaml` entirely.

## Updating CIDRs

Change `ETHIACK_BEACON_CIDRS` in `deployment.yaml` and re-apply:

```bash
kubectl apply -f deployment.yaml
```

The rolling restart triggers the container entrypoint, which calls `beacon update --cidrs` automatically before the health loop starts.

Alternatively, update immediately without restarting the pod:

```bash
kubectl -n ethiack exec deployment/ethiack-beacon -- beacon list
kubectl -n ethiack exec deployment/ethiack-beacon -- beacon update <beacon-id> --cidrs "10.0.0.0/8,192.168.0.0/16"
```

## Deleting a beacon

The deployment includes a `preStop` lifecycle hook that deregisters the beacon from the Ethiack portal before the container stops. Simply delete the deployment (and optionally the other resources):

```bash
kubectl -n ethiack delete deployment ethiack-beacon
kubectl -n ethiack delete pvc ethiack-beacon-state
kubectl delete namespace ethiack
```

The hook runs `beacon delete --yes` automatically during pod termination.
