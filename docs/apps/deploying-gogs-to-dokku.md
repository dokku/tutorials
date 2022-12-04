---
title:  "Deploying Gogs to Dokku"
date:   2016-04-19 02:13:01 -0400
categories: tutorials
tags:
  - dokku
  - ports
  - gogs
  - tutorial
---

Hot off the release of Dokku 0.6.3, here is a sweet tutorial made possible by the new port handling feature of Dokku.

> If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.

### What is Gogs?

[![dokku](/tutorials/assets/images/gogs-tutorial/favicon.ico)](/tutorials/assets/images/gogs-tutorial/favicon.ico)

> [Gogs](https://gogs.io) (Go Git Service) is a painless self-hosted Git service.

But what does that mean? Gogs is a self-hosted git management tool that can be used to host git repositories, issues, and releases on your own server.

For this tutorial, we will be deploying gogs to a single Dokku server running at least Dokku 0.6.3. You may upgrade your Dokku instance to this version or install it from scratch. Please setup any ssh keys necessary for pushing applications, as we will not go over initial installation.

### Application Preparation

Let's start by creating an application! While Dokku automatically creates an application on push, we will need to initialize some settings before the application will work, so it's best to do this manually.

```shell
dokku apps:create gogs
```

Before we continue, lets ensure that the proper domains and ports are setup for gogs. By default, the include `Dockerfile` exposes ports `3000` and `22` for the `http` and `ssh` processes, respectively. We will want our application to listen externally on port `80`, and will need to expose the `ssh` port on a different port as `22` is used by the host. We will not be using TCP load-balancing in our case, and instead will rely on the docker-options plugin to expose ssh properly.

```shell
# expose container `http` port 3000 on host `http` port 80
dokku proxy:ports-add gogs http:80:3000

# expose the container port 22 on host port 2222
dokku docker-options:add gogs deploy -p 2222:22
```

[![dokku](/tutorials/assets/images/gogs-tutorial/ports.png)](/tutorials/assets/images/gogs-tutorial/ports.png)

Next, we need to ensure there is persistent storage for Gogs. The Gogs docker image uses a directory mounted in `/data`, and we'll need either a docker volume or host directory to contain this data. For our purposes, we'll use a directory on the host.

> The official recommendation is to place persistent storage in the `/var/lib/dokku/data/storage` directory for cases where a user is not using a docker volume. As such, we'll create a subdirectory there for our application.

```shell
# create the directory
mkdir -p /var/lib/dokku/data/storage/gogs

# ensure the proper permissions are set for the gogs directory
chown -R dokku:dokku /var/lib/dokku/data/storage/gogs
```

We can now mount the directory as persistent storage using the official `storage` plugin. The storage plugin *does not* check that the directory or volume exists, hence the need to create it beforehand.

```shell
dokku storage:mount gogs /var/lib/dokku/data/storage/gogs:/data
```

At this point, we need to setup our database for gogs. We will use the official [dokku-mysql](https://github.com/dokku/dokku-mysql) plugin, though you are welcome to use the [dokku-postgres](https://github.com/dokku/dokku-postgres) plugin or any other MySQL/Postgres installation you choose.

```shell
dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql
dokku mysql:create gogs
dokku mysql:link gogs gogs
```

[![dokku](/tutorials/assets/images/gogs-tutorial/mysql.png)](/tutorials/assets/images/gogs-tutorial/mysql.png)

### Pushing our Code

Lets clone gogs locally. I have a ~/src directory in which I place all the applications I am currently working on and deploying, though any such directory should be fine.

```shell
git clone git@github.com:gogits/gogs.git ~/src/gogs
```

When pushing an application, you need to set the dokku host. For the purposes of this tutorial, the hostname of our dokku server is `dokku.me`. Note that the application name - `gogs` in this case - should be appended to the remote so that dokku knows what application you are pushing.

```shell
git remote add dokku dokku@dokku.me:gogs
```

And finally you can trigger a push of the gogs repository to your dokku server. This push will take a while as a few things need to happen:

- The actual repository needs to be pushed to your server
- The docker image must be built

Not to worry though! Everything from this point on is cake :)

```shell
git push dokku master
```

### Configuring Gogs

Here is where it gets slightly tricky. You will want to use the following settings to configure Gogs:

- MySQL connection information can be retrieved from `dokku mysql:info gogs`
- Set the SSH port as `2222`. Gogs will use this to format your projects' SSH connection info in the UI.
- Do not change the application port.
- The application url should be changed to match your attached domain. In our case, it would be `http://gogs.dokku.me/`
- The domain field should also be changed to match your attached domain, but without the 'http'. In our case, it would be `gogs.dokku.me`. This will also be used to format your projects' connection info the UI.
- Any of the optional settings can be configured as you wish.

Once you submit the form, you should have a working Gogs Installation!

[![dokku](/tutorials/assets/images/gogs-tutorial/screenshot.png)](/tutorials/assets/images/gogs-tutorial/screenshot.png)

### Wrap-up

As we displayed above, Dokku's rich featureset allows developers to quickly and easily setup applications as complex as a git management tool. With it's ability to deploy Dockerfile applications, proxy ports on the fly, and mount persistent storage, Dokku is a great tool to have in your deployment arsenal. Here's hoping it only gets better!

---

If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.
