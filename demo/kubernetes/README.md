# Kubernetes examples

The `datalyze/vaultify` image copies the latest vaultify binary to the target path `/opt/vaultify/vaultify`. If you share this path inside the pod, every container can use vaultify to decrypt its own envs.

## Secrets

You need to create the secrets by hand. It's best to pack both, the ansible vault file and the key, into the same secret. This simplifies the mount config.

```bash
kubectl create secret generic vault --from-file=../vault --from-file=../key
```

## Postgres deployment

This uses `initContainers` to take care vaultify exists inside the pod.

```bash
kubectl apply -f postgres-deployment.yaml
```

## System wide binary

If you don't wanne add an `initContainer` to every pod, you can use system wide 'installed' vaultify. This example uses a daemonset to copy the vaultify binary to a host path. From there you can mount it to any pod you wanne take use of vaultify. The daemonset takes care that every node has a copy of vaultify. A down side of this approach is, that a daemonset can't be run one-time only. The workaround is the `pause` container. 

#### Alternatives

* cronjob
* job controller
* static container

```bash
kubectl apply -f system-wide.yaml
```

## Manual login

To test the connection with cli, simply change the clients job `arg` to `args: ["sleep", "36000"]` and exec into the container:

```bash
kubectl exec -it $(kubectl get pods --selector=app=postgres-client-vaultify-test -o jsonpath='{.items[0].metadata.name}') -- /opt/vaultify/vaultify run bash
```

Now it's up to you to connect to the db and query, what ever you want:

```bash
psql -U tester -d tester -h postgres-vaultify-test
```
