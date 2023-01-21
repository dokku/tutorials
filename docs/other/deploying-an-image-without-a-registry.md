---
title:  "Deploying an image without a registry"
date:   2023-01-20 22:39:00 -0400
categories: general
tags:
  - dokku
  - deploying
---

To deploy an image from CI without an intermediate registry, we can run the following series of commands.

!!! note

    This tutorial assumes the app being deployed is named `node-js-app` and the Dokku server's hostname is `dokku.me`. Please modify these values as appropriate.


### Building the image

First, we'll assume the image is built. The following is one example for building a docker image, though your setup may vary. The image repository _must not_ be `dokku/`, as that namespace is used internally for tagging images by Dokku.

```shell
# a good tag to use is the commit sha of your build
docker image build --tag app/node-js-app:2935cc3d .
```

### Loading the image onto the host

Next, we save the image to a file. This can be done with the `docker image save` command:

```shell
docker image save --ouput node-js-app.tar
```

The image must then be loaded on the remote server. This should be performed with the `docker load` command, and must be performed by a user that has access to the docker daemon. Note that because this command is not exposed by Dokku, a user other than `dokku` must be used for the ssh command.

```shell
cat node-js-app.tar | ssh root@dokku.me "docker load"
```

Alternatively, you can save the image and load it in one command like so:

```shell
docker image save | ssh root@dokku.me "docker load"
```

### Deploying the image

Finally, we can deploy the image using the `git:from-image` Dokku command.

```shell
ssh dokku@dokku.me git:from-image node-js-app app/node-js-app:2935cc3d
```
