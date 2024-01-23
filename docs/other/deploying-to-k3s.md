---
title:  "Deploying to a Dokku-managed k3s cluster"
date:   2023-01-23 11:28:00 -0400
categories: general
tags:
  - dokku
  - k3s
  - cluster
---

New in [0.33.0](https://github.com/dokku/dokku/releases/tag/v0.33.0), Dokku natively supports deploying to a multi-node setup via k3s. Dokku can be used to connect k3s servers together to provide high availability and elastic capacity to your application, allowing you to weather outages of individual servers. The following tutorial briefly goes over how to setup and interact with Dokku.

For more information, see the official [scheduler-k3s](https://dokku.com/docs/deployment/schedulers/k3s/) documentation.

### Single-node cluster

Initialize the cluster in single-node mode. This will start k3s on the Dokku node itself.

```shell
# must be run as root
dokku scheduler-k3s:initialize
```

The above command will initialize a cluster with the following configuration:

- etcd distributed backing store
- Wireguard as the networking flannel
- K3s automatic upgrader
- Longhorn distributed block storage
- Traefik configured to run on all nodes in the cluster

Additionally, an internal token for authentication will be automatically generated. This is stored with k3s, and should be backed up appropriately.

The K3s scheduler plugin will automatically pick up any newly configured registry backends and ensure nodes in the cluster have the credentials in place for pulling images from the cluster.

```shell
# hub.docker.com
dokku registry:login hub.docker.com $USERNAME $PASSWORD
```

To ensure images are pushed and pulled from the correct registry, set the correct `server` registry property. This can be set on a per-app basis, but we will set it globally here for this tutorial.

```shell
dokku registry:set --global server hub.docker.com
```

If using docker hub, you'll need to use a custom repository name. This can be set via a global template, allowing users access to the app name as the variable `AppName` as shown below.

```shell
dokku registry:set --global image-repo-template "my-awesome-prefix/{{ .AppName }}"
```

Additionally, apps should be configured to push images on the release phase via the `push-on-release` registry property.

```shell
dokku registry:set --global push-on-release true
```

As routing is handled by traefik managed on the k3s plugin, set the proxy plugin to `k3s` as well.

```shell
dokku proxy:set --global k3s
```

Ensure any other proxy implementations are disabled. Typically at least nginx will be running on the Dokku host and should be stopped if the host is used as load balancer.

```shell
dokku nginx:stop
```

Finally, set the scheduler to `k3s` so that app deploys will work on k3s.

```shell
dokku scheduler:set --global selected k3s
```

At this point, all app deploys will be performed against the k3s cluster.

> [!NOTE]
> HTTP requests for apps can be performed against any node in the cluster. Without extra configuration, many other ports may also be available on the host. For security reasons, it may be desirable to place the k3s cluster behind one or more TCP load balancers while shutting off traffic to all cluster ports. Please consult your hosting provider for more information on how to provision a TCP load balancer and shut off all ports other than 22/80/443 access to the outside world.

### Running a multi-node cluster

> [!WARNING]
> Certain ports must be open for cross-server communication. Refer to the [K3s networking documentation](https://docs.k3s.io/installation/requirements?os=debian#networking) for the required open ports between servers prior to running the command.

For high-availability, it is recommended to add both worker and server nodes to the cluster. Dokku will default to starting the cluster with an embedded Etcd database backend, and is ready to add new worker or server nodes immediately.

When running a multi-node cluster, initialize k3s with the `--taint-scheduling` flag. This will start the k3s on the Dokku node in server mode. Server nodes only allow critical addons to be run, such as the control plane, etcd, the load balancer, etc.

```shell
# must be run as root
dokku scheduler-k3s:initialize --taint-scheduling
```

When attaching an worker or server node, the K3s plugin will look at the IP associated with the `eth0` interface and use that to connect the new node to the cluster. To change this, set the `network-interface` property to the appropriate value.

```shell
dokku scheduler-k3s:set --global network-interface eth1
```

Dokku will connect to remote servers via the `root` user with the `dokku` user's SSH key pair. Dokku servers may not have an ssh key pair by default, but they can be generated as needed via the `git:generate-deploy-key` command.

```shell
dokku git:generate-deploy-key
```

This key can then be displayed with the `git:public-key` command, and added to the remote server's `/root/.ssh/authorized_keys` file.

```shell
dokku git:public-key
```

Multiple server nodes can be added with the `scheduler-k3s:cluster-add` command. This will ssh onto the specified server, install k3s, and join it to the current Dokku node in server mode.

```shell
dokku scheduler-k3s:cluster-add --role server --taint-scheduling ssh://root@server-1.example.com
```

If the server isn't in the `known_hosts` file, the connection will fail. This can be bypassed by setting the `--insecure-allow-unknown-hosts` flag:

```shell
dokku scheduler-k3s:cluster-add --role server --taint-scheduling --insecure-allow-unknown-hosts ssh://root@worker-1.example.com
```

> [!NOTE]
> Only the initial Dokku server will be properly configured for push deployment, and should be considered your git remote. Additional server nodes are for ensuring high-availability of the K3s etcd state. Ensure this server is properly backed up and restorable or deployments will not work.

Worker nodes are used to run. To add an worker, run the `scheduler-k3s:cluster-add` with the `--role worker` flag. This will ssh onto the specified server, install k3s, and join it to the current Dokku node in worker mode. Workers are typically used to run app workloads.

```shell
dokku scheduler-k3s:cluster-add --role worker ssh://root@worker-1.example.com
```

### Deploying an app

To demonstrate multi-server functionality, we can deploy the Dokku [smoke-test-app](https://github.com/dokku/smoke-test-app) with the following commands.

First, create the app:

```shell
dokku apps:create smoke-test-app
```

Next, add any desired domains to the app. If running a single-node cluster, the DNS for each domain should point to your Dokku node. For multi-node clusters, point any DNS records at your server node IP addresses.

```shell
dokku domains:set smoke-test-app.dokku.me
```

Finally, deploy the app. For demo purposes, we'll use the `git:sync` command against the Dokku server.

```shell
dokku git:sync --build smoke-test-app https://github.com/dokku/smoke-test-app.git
```

At this point, you should be able to browse to `smoke-test-app.dokku.me` in your browser to see the response from the app.
