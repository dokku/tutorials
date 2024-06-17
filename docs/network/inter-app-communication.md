---
title:  "Inter-app Communication in Dokku"
date:   2024-06-17 12:42:00 -0400
tags:
  - dokku
  - network
---

In the microservice world, it may be necessary to communicate from one app container to another. Dokku makes this fairly straightforward by building upon docker networking.

## Creating a network

In order to communicate across multiple containers - whether they be within the same app or separate apps - a Docker network must first be created. This can be performed manually via the `dokku network:create` command. This creates an attachable network, allowing containers to be associated with the network at a later date.

```shell
dokku network:create custom-network
```

Note that the following network names are invalid:

- none
- bridge
- host

## Attaching an app to the network

Dokku allows users to specify different phases for network attachment. While users will _generally_ want to utilize `attach-post-deploy` as it will ensure the app is healthy before exposing it on the network, there are specific use cases for each phase:

- `attach-post-create`: Associates the network after a container is created but before it is started. Commonly used for cross-app networking.
- `attach-post-deploy` Associates the network after the deploy is successful but before the proxy is updated. Used for cross-app networking when healthchecks must be invoked first.
- `initial-network`: Associates the network at container creation. Typically blocks access to services and external routing, and is almost always the incorrect network phase.

For the purposes of this tutorial, we will use `attach-post-create`.

```shell
dokku network:set node-js-app attach-post-create custom-network
```

The above is sufficient when communicating with different processes running under the same app, but if communicating across applications, each app _must_ be added to the same network.

## Connecting to processes

When a container created for a deployment is being attached to a network - regardless of which network property was used - a network alias of the pattern `APP.PROC_TYPE` will be added to all containers. This can be used to load-balance requests between containers. For an application named `node-js-app` with a process type of web, the network alias - or resolvable DNS record within the network - will be:

```
node-js-app.web
```

The fully-qualified URL for the resource will depend upon the `PORT` being listened to by the application. Applications built via buildpacks will have their `PORT` environment variable set to `5000`, and as such internal network requests for the above example should point to the following:

```
http://node-js-app.web:5000
```

> [!IMPORTANT]
> Applications may listen on other ports, and typically do in the case of Dockerfile deployments. For more information on how ports are specified for applications, please refer to the [port management documentation](/docs/networking/port-management.md).

If connecting from the `node-js-app` to the `python-app`'s `web` process that is listening on port 5000, we can try the following:

```shell
dokku enter node-js-app web
curl http://python-app.web:5000
```

Other types of requests - tcp, udp, grpc - will also work with the appropriate library.
