# vaultify

Vaultify is a little application that reads secrets from an ansible-vault file and injects them into a process. An ansible-vault file is an encrypted file used by ansible. The contemplates usecase is the main entrypoint for a containerized application, e.g. docker-entrypoint. Using a vault file instead if plain text enables simpler password management, e.g. you can push a vault file with development passwords into an applications source code repository. A developer only needs to add the vault files key on setup once.

Having a single binary enables you to 'inject' the vaultify functionality into a third party container, e.g. postgres, by simply adding it to the container, replacing the entrypoint and calling the containers main entrypoint and command.

## Functionality

Consider the following content inside an ansible-vault file.

```bash
DB_PASSWORD=super-secret-password
TEST=test123
DB_HOST=db
DB_USER=backend
DB_NAME=backend
DB_PORT=5432
```

Vaultify takes the OSes environment variables and replaces the value marked within curly braces: `<<VALUE_INSIDE_VAULT_FILE>>`. Doing so you can also combine new environment variable with values from the vault, e.g. `postgres://<<DB_USER>>:<<DB_PASSWORD>>@<<DB_HOST>>:<<DB_PORT>>/<<DB_NAME>>`. Vaultify reads the ansible vault from `/etc/vault/vault` and the key `/etc/vault/key`. The keyfile contains the password in plaintext.

```bash
export VAULTIFY_DB_PASSWORD="<<DB_PASSWORD>>"
export VAULTIFY_TEST="<<TEST>>"
export VAULTIFY_POSTGRES_PASSWORD="<<DB_PASSWORD>>"
export VAULTIFY_DB_URI="postgres://<<DB_USER>>:<<DB_PASSWORD>>@<<DB_HOST>>:<<DB_PORT>>/<<DB_NAME>>"

./bin/vaultify run bash
export | grep VAULTIFY
```

should show the following result:

```bash
export VAULTIFY_DB_PASSWORD='super-secret-password'
export VAULTIFY_DB_URI='postgres://backend:super-secret-password@db:5432/backend'
export VAULTIFY_POSTGRES_PASSWORD='super-secret-password'
export VAULTIFY_TEST='test123'
```

## Docker Image

A prepared image is available on https://hub.docker.com as `datalyze/vaultify:latest`. The is based on busybox and copies the vaultify binary from `/vaultify` to the volume `/opt/vaultify`. Doing so you can simply mount `/opt/vaultify` inside another container and overwriting it's entrypoint with `/opt/vaultify/vaultify`.

## Examples

### Kubernetes

The `datalyze/vaultify` image copies the latest vaultify binary to the target path `/opt/vaultify/vaultify`. If you share this path inside the pod, every container can use vaultify to decrypt its own envs.

##### Secrets

You need to create the secrets by hand. It's best to pack both, the ansible vault file and the key, into the same secret. This simplifies the mount config.

```bash
kubectl create secret generic vault --from-file=../vault --from-file=../key
```

#### Postgres deployment

This uses `initContainers` to take care vaultify exists inside the pod.

```bash
kubectl apply -f postgres-deployment.yaml
```

#### System wide binary

If you don't wanne add an `initContainer` to every pod, you can use system wide 'installed' vaultify. This example uses a daemonset to copy the vaultify binary to a host path. From there you can mount it to any pod you wanne take use of vaultify. The daemonset takes care that every node has a copy of vaultify. A down side of this approach is, that a daemonset can't be run one-time only. The workaround is the `pause` container. 

##### Alternatives

* cronjob
* job controller
* static container

```bash
kubectl apply -f system-wide.yaml
```

#### Manual login

To test the connection with cli, simply change the clients job `arg` to `args: ["sleep", "36000"]` and exec into the container:

```bash
kubectl exec -it $(kubectl get pods --selector=app=postgres-client-vaultify-test -o jsonpath='{.items[0].metadata.name}') -- /opt/vaultify/vaultify run bash
```

Now it's up to you to connect to the db and query, what ever you want:

```bash
psql -U tester -d tester -h postgres-vaultify-test
```

### Docker

You'll find a prepared plain docker example bundles within the Makefile. Calling `make test-docker-pg test-docker-pg-connect test-docker-down` starts the complete docker test. The example starts a postgres server and performs a simple select on the new database.

```bash
docker run -d --rm \
  -v $PWD/bin/vaultify:/vaultify:ro \
  -v $PWD/demo/vault:/etc/vault/vault:ro \
  -v $PWD/demo/key:/etc/vault/key:ro \
  -e POSTGRES_PASSWORD="<<DB_PASSWORD>>" \
  -e POSTGRES_USER=tester \
  -e PGPASSWORD="<<DB_PASSWORD>>" \
  --entrypoint /vaultify \
  --name vaultify-db \
  postgres \
  run docker-entrypoint.sh postgres

# connect to the container and perform a select
docker exec -it vaultify-db \
  psql -U tester -d tester -h localhost -p 5432 -c "SELECT 1 as test"

# stop the container
docker container stop vaultify-db
```

Inside `demo/` you'll also find the `docker-compose.yaml` file, containing the same example, but compose ready.

```bash
cd demo
docker-compose up -d
docker wait vaultify-db-client
docker-compose logs client
# clean up, remove volume and network
docker-compose down --volume --remove-orphans
```

or you can use `make`

```bash
make test-docker-compose
```

### Docker Swarm

To prevent building seperate images with vaultify included, you can copy vaultify to a volume shared with each service in the stack. The image hosted at hub.docker.com `datalyze/vaultify:latest` is prepared to copy vaultify into the directory `/opt/vaultify`. If you mount the volume inside another container you can set the entrypoint to `/opt/vaultify/vaultify`.

`demo/swarm.yaml` contains a prepared swarm example. You can deploy it on youre own or using the make commands.

```bash
cd demo
docker stack deploy -c swarm.yaml vaultify-demo

# or with make
make test-docker-swarm-deploy
```

You can now check the logs of the `postgres` and `client` services.

```bash
docker service logs -f postgres
docker service logs -f client
```

## FAQ

### My node process does not see replaced envs

Start your node process in a subshell:

```bash
vaultify run sh -c 'node server.js'
```

or use the `run-sub-sh` command:

```bash
vaultify run-sub-sh node server.js
```