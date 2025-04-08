---
title:  "Deploying Bugsink to Dokku"
date:   2025-04-07 12:00:00 +0200
categories: tutorials
tags:
  - dokku
  - bugsink
  - tutorial
---

[Bugsink](https://www.bugsink.com/) is a sentry-compatible Error Tracker with a strong focus on being _very_ easy to
self-host.

That focus makes it an excellent candidate for deployment on Dokku, as it is a simple application that can be deployed
with minimal configuration.

This tutorial explains how to deploy a self-hosted instance of Bugsink on a Dokku server. It assumes:

* You have a working Dokku setup with SSH access
* The domain is already pointing to your Dokku server.
* Subdomains to your domain _also_ point to your Dokku server.

### Set up a MySQL service

Bugsink can use either SQLite, MySQL or Postgres as its database backend. SQLite is actually a surprisingly stable and
performant way to run Bugsink, but in cloud-like environments (such as dokku) it's usually a better fit to use a
separate database service, as this allows for persistent storage across container restarts. In this tutorial we'll pick
MySQL.

We'll set up the MySQL service first, so that it's there waiting for us when we set up Bugsink itself.

Install the official MySQL plugin for Dokku:

```shell
# on your dokku host
sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git --name mysql
```

Create a new MySQL service named `bugsink-db`:

```shell
# on your dokku host
dokku mysql:create bugsink-db
```

### Create the Bugsink app

Then, we create the actual application. This is the name that will be used to refer to the application in the Dokku CLI.


```shell
# on your dokku host
dokku apps:create bugsink
```

We also instruct Dokku to keep the git directory of the application. This is needed because when deploying Bugsink
from source (as we are doing in this tutorial) Bugsink needs the `.dit` directory to figure out what its version number
is.

```shell
# on your dokku host
dokku git:set bugsink keep-git-dir true
```

Finally, we link the database to our application:

```shell
# on your dokku host
dokku mysql:link bugsink-db bugsink
```

This will set the `DATABASE_URL` environment variable in your application, pointing to the MySQL database.


#### Setting environment variables

Bugsink needs a [few more environment variables](https://www.bugsink.com/docs/settings/)

```shell
# on your dokku host
dokku config:set bugsink \
    CREATE_SUPERUSER=admin:SOME_SECRET_PASSWORD
    SECRET_KEY=$(openssl rand -hex 32) \
    BASE_URL=http://bugsink.dokku.me
```

### Pushing the Bugsink code

Lets clone Bugsink locally (it's [source available](https://github.com/bugsink/bugsink/), so we can push it to our dokku server. 

```shell
# on your local machine
cd some-base-dir
git clone git@github.com:bugsink/bugsink.git
cd bugsink
```

When pushing an application, you need to set the dokku host. For the purposes of this tutorial, the hostname of our
dokku server is `dokku.me`. Note that the application name - `bugsink` in this case - should be appended to the remote so
that dokku knows what application you are pushing.

```shell
# on your local machine
git remote add dokku dokku@dokku.me:bugsink
git push dokku main
```

This should print a bunch of logs on screen, showing the successful installation of Bugsink.

Now, navigate to bugsink.dokku.me. You should see the Bugsink login screen there.
Log in with the credentials you provided while setting up the environment variables.
You can now [connect SDKs and start sending events](https://www.bugsink.com/docs/quickstart/)

### Wrap-up

As we displayed above, Dokku's rich featureset allows developers to quickly and easily setup applications. In this case,
the application has been optimized for easy deployment using Docker.

Dokku is a great tool to have in your deployment arsenal.
