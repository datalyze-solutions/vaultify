# vaultify

Vaultify is a little application that reads secrets from an ansible-vault file and injects them into a process. An ansible-vault file is an encrypted file used by ansible. The contemplates usecase is the main entrypoint for a containerized application, e.g. docker-entrypoint. Using a vault file instead if plain text enables simpler password management, e.g. you can push a vault file with development passwords into an applications source code repository. A developer only needs to add the vault files key on setup once.

Having a single binary enables you to 'inject' the vaultify functionality into a third party container, e.g. postgres, by simply adding it to the container, replacing the entrypoint and calling the containers main entrypoint and command.

## Functionality

Consider the following content inside an ansible-vault file.

```bash
DB_PASSWORD=super-secret-password
TEST=test123
DB_HOST=db
DB_USER=bosch
DB_NAME=backend
DB_PORT=5432
```

Vaultify takes the OSes environment variables and replaces the value marked within curly braces: `{{VALUE_INSIDE_VAULT_FILE}}`. Doing so you can also combine new environment variable with values from the vault, e.g. `postgres://{{DB_USER}}:{{DB_PASSWORD}}@{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}`. Vaultify reads the ansible vault from `/etc/vault/vault` and the key `/etc/vault/key`. The keyfile contains the password in plaintext.

```bash
export VAULTIFY_DB_PASSWORD= "{{DB_PASSWORD}}"
export VAULTIFY_TEST= "{{TEST}}"
export VAULTIFY_POSTGRES_PASSWORD= "{{DB_PASSWORD}}"
export VAULTIFY_DB_URI= "postgres://{{DB_USER}}:{{DB_PASSWORD}}@{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}"
# will not be replaced, cause it does not match the {{}} formatters
export VAULTIFY_ALTERNATIVE_TEST= "<<TEST>>"

./bin/vaultify run bash
export | grep VAULTIFY
```

should show the following result:

```bash
export VAULTIFY_ALTERNATIVE_TEST='<<TEST>>'
export VAULTIFY_DB_PASSWORD='super-secret-password'
export VAULTIFY_DB_URI='postgres://bosch:super-secret-password@db:5432/backend'
export VAULTIFY_POSTGRES_PASSWORD='super-secret-password'
export VAULTIFY_TEST='test123'
```

## Examples

### Docker

You'll find a prepared plain docker example bundles within the Makefile. Calling `make test-docker-pg test-docker-pg-connect test-docker-down` starts the complete docker test. The example starts a postgres server and performs a simple select on the new database.

```bash
docker run -d --rm \
  # mount the vaultify binary into the container
  -v $PWD/bin/vaultify:/vaultify:ro \
  # mount the vault and key into the container
  -v $PWD/demo/vault:/etc/vault/vault:ro \
  -v $PWD/demo/key:/etc/vault/key:ro \
  # this values will be replaced
  -e POSTGRES_PASSWORD={{DB_PASSWORD}} \
  -e POSTGRES_USER=tester \
  -e PGPASSWORD={{DB_PASSWORD}} \
  # configure vaultify to be the new entrypoint
  --entrypoint /vaultify \
  --name vaultify-db \
  postgres:12 \
  # call the 'run' command of vaultify
  # to call the containers entrypoint ("docker-entrypoint.sh") with it's command ("postgres")
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
# clean up, remove volume and network
docker-compose down -v
```
