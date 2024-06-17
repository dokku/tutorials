---
title:  "Connecting to network processes running directly on the host"
date:   2024-06-17 11:33:00 -0400
tags:
  - dokku
  - network
---

On occasion, it may be necessary to connect to processes that are running on the same host _but not_ within a docker container. Users may opt to perform this via either host-based networking or by using a host gateway.

## Host Networking

Using host-based networking allows processes running within Docker containers to completely bypass the networking stack. Processes within containers will listen _directly on_ the host. In effect, this means that a process within a container listening on port 80 will _also_ be listening on the host via port 80, and no other process on the host can utilize that port until the container process vacates it.

Another by-product of utilizing host networking is that connecting to `127.0.0.1:$PORT` within a container will allow the container to connect to any process running on the host that is listening on `$PORT` _or_ any other container that is listening on `$PORT` and utilizing host-based networking.

To use host-based networking, start by adding the `--net=host` option to the app. For this example, the option will be added to all three phases.

```shell
dokku docker-options:add node-js-app build,deploy,run --net=host
```

The various phases provide differing functionality:

- `build`: Allows build processes to talk to the host. Only applies to `herokuish`-based builds
- `deploy`: All deployed containers will be able to communicate on host networking.
- `run`: All processes in one-off (`dokku run`) and cron containers will be able to communicate on the host network.

Once the option is added, the app must be rebuilt. Docker options will otherwise not come into effect as running containers are largely immutable and their network layer cannot change.

```shell
dokku ps:rebuild node-js-app
```

In a new shell session, start a process on the host to respond to requests. A `python3` server can serve up some temporary files:

```shell
mkdir /tmp/test-server
cd /tmp/test-server/
echo "hello world" > /tmp/test-server/index.html
python3 -m http.server
```

Finally, in your original shell session, enter the app and make a request to the test process. The hostname for requests will be `127.0.0.1`. Note that this assumes `curl` is available within the container:

```shell
dokku enter node-js-app web
curl 127.0.0.1:8000
```

A `hello-world` message should be the response.

Note that any process within a host-based network, host-based processses listening on either all interfaces _or_ host-based processes listening on localhost will be accessible to the container with host-based networking.

## Host Gateway

Rather than expose a process directly on a host, a host-gateway can be attached to the container. This allows for more complex networking usage while exposing the host as a dns entry in the container. Additionally, ports used by container processes are not reserved on the host, allowing for overlap across multiple containers.

Start by adding the `--add-host=host.docker.internal:host-gateway` option to the app. For this example, the option will be added to all three phases.

```shell
dokku docker-options:add node-js-app build,deploy,run --add-host=host.docker.internal:host-gateway
```

The various phases provide differing functionality:

- `build`: Allows build processes to talk to the host. Only applies to `herokuish`-based builds
- `deploy`: All deployed containers will be able to communicate on host networking.
- `run`: All processes in one-off (`dokku run`) and cron containers will be able to communicate on the host network.

Once the option is added, the app must be rebuilt. Docker options will otherwise not come into effect as running containers are largely immutable and their network layer cannot change.

```shell
dokku ps:rebuild node-js-app
```

In a new shell session, start a process on the host to respond to requests. A `python3` server can serve up some temporary files:

```shell
mkdir /tmp/test-server
cd /tmp/test-server/
echo "hello world" > /tmp/test-server/index.html
python3 -m http.server
```

Finally, in your original shell session, enter the app and make a request to the test process. The hostname for requests will be `host.docker.internal`. Note that this assumes`curl` is available within the container:

```shell
dokku enter node-js-app web
curl host.docker.internal:8000
```

A `hello-world` message should be the response.

Note that _only_ host processes listening on all interfaces - `0.0.0.0` - will be accessible via this method. Attempting to communicate to a host process listening on localhost - `127.0.0.1` - will result in a failure to connect.

## Which method should you choose?

Ultimately, each method has tradeoffs. Host-based networking allows complete access to networking on the host, trading security for simplicity, while host gateways provide better security in exchange for requiring that a process listen on all interfaces. The method you choose depends on your needs, and each should be considered after weighing the pros and cons for your situation.

The Dokku project recommends host-gateway method for most cases, though users should feel free to pick what works best for their app.
