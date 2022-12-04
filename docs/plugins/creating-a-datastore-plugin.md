---
title:  "Creating a Datastore plugin"
date:   2021-11-14 12:5:00 -0400
tags:
  - dokku
  - plugins
---

Ever wanted to write a datastore plugin? This tutorial shows how we create official datastore plugins.

> If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.

### Initializing the plugin

First, we'll start by cloning an existing datastore plugin. I'll choose the `postgres` plugin.

```shell
git clone https://github.com/dokku/dokku-postgres dokku-meillisearch
cd dokku-meillisearch
rm -rf .git
```

Once this is done, we can modify the `plugin.toml` to have the following contents:

```toml
[plugin]
description = "dokku meillisearch service plugin"
version = "0.0.1"
[plugin.config]
```

### Reconfiguring the plugin

Now begins the great find/replace. We'll do the following case-sensitive replacements:

- `postgres` `meillisearch` 
- `Postgres` `Meillisearch`
- `POSTGRES` `MEILLISEARCH`

After the find/replace, we'll need to configure the plugin correctly. There should be a `config` file that contains runtime configuration for the plugin. We'll need to change the following in this file:

- `PLUGIN_DATASTORE_PORTS`: A bash array containing a list of ports exposed by the service. In many cases, this will be a single port. All ports should be listed here. The first port in the list is used when linking the service to an app.
    - For `meillisearch`, the config should look as follows `export PLUGIN_DATASTORE_PORTS=(7700)`
- `PLUGIN_DATASTORE_WAIT_PORT`: This should be the primary port that Dokku waits to be ready when creating the service. Usually this will be the port used to link the service to an app.
    - For `meillisearch`, the config should look as follows `export PLUGIN_DATASTORE_WAIT_PORT=7700`
- `PLUGIN_SCHEME`: The value of this is used in the DSN. Do not leave it blank. It can usually be the lowercase version of the datastore name, but sometimes may need to be something different.
    - For `meillisearch`, the config should look as follows `export PLUGIN_SCHEME=http`
- `PLUGIN_DEFAULT_ALIAS`: This is used as the prefix for the `_URL` value. DATABASE_URL is pretty normal for sql datastores.
    - For `meillisearch`, the config should look as follows` export PLUGIN_DEFAULT_ALIAS="MEILLISEARCH"


The `config` file also contains a `PLUGIN_UNIMPLEMENTED_SUBCOMMANDS` shell array. This contains a list of commands that are not supported by the plugin. For sql-like plugins, this is usually empty, but sometimes certain functionality is not supported by the datastore (such as backup/restore or connecting to the service using a repl). In our case, we'll set the following value.

```shell
export PLUGIN_UNIMPLEMENTED_SUBCOMMANDS=("backup" "backup-auth" "backup-deauth" "backup-schedule" "backup-schedule-cat" "backup-set-encryption" "backup-unschedule" "backup-unset-encryption" "clone" "connect" "export" "import")
```

This can always be revisited in the future as functionality becomes available to the datastore.

Once this is set, we need to update the default Docker image the datastore plugin will use. This is contained within the `Dockerfile.` As of the time of writing, the latest stable image tag is `v0.23.1`, so we'll have the following as the `Dockerfile` contents:

```Dockerfile
FROM getmeili/meilisearch:v0.23.1
```

These cover the general changes. Now on to function updates.

### Customizing Commands

90% of the plugin is templated, but datastore-specific functions are stored in the `functions` file. We'll go over each of these below (and describe the customizations for `meilisearch`).


- `service_connect`: Connects to the datastore via a repl. The repl _must_ be available in the base image in use, and not any customization.
    - For `meillisearch`, we'll replace the existing `psql` call with `dokku_log_fail "Not yet implemented"`
- `service_create`: Usually only customized if there are password needs (either the datastore doesn't support a password or supports a root password in addition to the normal one).
    - For `meillisearch`, we don't need to customize anything.
- `service_create_container`: The meat and potatos. This creates the container and intiailizes data for the container (if necessary).
    - For `meillisearch`, we can drop the code that initiliazes container database (from ~line 96-105, which contains the `service_port_unpause` call). Additionally, the `ID=$(docker run ...)` command should become the following:

        ```
        ID=$(docker run --name "$SERVICE_NAME" $MEMORY_LIMIT $SHM_SIZE -v "$SERVICE_HOST_ROOT/data:/data.ms" -e "MEILI_MASTER_KEY=$PASSWORD" -e "MEILI_HTTP_ADDR=0.0.0.0:7700" -e "MEILI_NO_ANALYTICS=true" --env-file="$SERVICE_ROOT/ENV" -d --restart always --label dokku=service --label dokku.service=meillisearch "$PLUGIN_IMAGE:$PLUGIN_IMAGE_VERSION" $CONFIG_OPTIONS)
        ```

- `service_export`: Used for exporting the service data. You can implement this if the container has some way to export the data to stdout
    - For `meillisearch`, we'll replace the existing `psql` call with `dokku_log_fail "Not yet implemented"`
- `service_import`: Analogous to `service_export`, used for importing the service data. You can implement this if the container has some way import the data from stdin.
    - For `meillisearch`, we'll replace the existing `psql` call with `dokku_log_fail "Not yet implemented"`
- `service_start`: The only time this is customized is when the service either has no passwords (so the password check is removed) or has a secondary, root password (so we add another check).
    - For `meillisearch`, the existing checks the `Postgres` plugin performs are enough.
- `service_url`: This outputs the default DSN-formatted connection string. Docker exposes other variables containing just IPs, PORTs, and other values from the config, so it is _heavily_ encouraged to not come up with your own format here.
    - For `meillisearch`, this should become the following:

        ```
        echo "$PLUGIN_SCHEME://:$PASSWORD@$SERVICE_DNS_HOSTNAME:${PLUGIN_DATASTORE_PORTS[0]}"
        ```

### Fixing tests

Usually the following should be modified for tests. Below contains the changes for our meillisearch plugin.

- Tests matching unimplemented commands should be removed. For `meillisearch`, this means deleting the following files:
    - `tests/service_clone.bats`
    - `tests/service_connect.bats`
    - `tests/service_export.bats`
    - `tests/service_import.bats`
- Port references should be updated. In our case, a find/replace of `5432` with `7700` is enough for this.
- `username:password` need to conform to how the datastore works. For `meillisearch`, we can do two find-replacements:
    - `//u:p` => `//:p`
    - `//meillisearch:$password` => `//:$password`
- The plugin scheme should be updated. This is done with two  find/replace calls:
    - `meillisearch://` => `http://`
    - `meillisearch2` => `http2`
- The "database" in the DSN should be updated to match the plugin's `service_url` format. In our case, we'll need a few find-replacements:
    - `/db"` => `"` (basically removing the suffix)
    - `/l"` => `"` (basically removing the suffix)
    - `/test_with_underscores"` => `"` (basically removing the suffix)
    - `/db`: there will be one instance of this in a `config:set` call. The string should just be removed.
- The `dsn` key should be updated to match the `PLUGIN_DEFAULT_ALIAS`. For `meillisearch`, we can do the following find/replace:
    - `DATABASE_URL` => `MEILLISEARCH_URL`

### Regenerating the README.md

The readme is generated by reading through the plugin source and generating help based on the `config` file and the source of each subcommand. It is enhanced by files in the `docs` folder. For our use case, we'll remove everything in the `docs` folder except for `docs/README.`

This can be done in a single call to `bin/generate` a script included with each plugin that requries `python3`.

### Commiting everything

If everything went well, we can commit and push our new service plugin to Github. The plugin should automatically run tests in Github Actions, at which point you can catch any lingering errors.
---

If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.
