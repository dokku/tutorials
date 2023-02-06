---
title:  "Using Websockets with Nginx"
date:   2023-02-06 16:10:00 -0400
categories: general
tags:
  - dokku
  - nginx
  - websockets
---

!!! note

    The code for this tutorial is available on [Github](https://github.com/dokku/websocket-example)

In many frameworks, a separate process must be run to expose websockets due to the underlying language in use. This tutorial assumes that is the case, and therefore your app is assumed to run two processes, a `web` and a `ws` process. The following is an example Procfile for our `websocket-example` application.

```yaml
web: websocket-example web
ws: websocket-example ws
```

To route requests to the `ws` process, a custom `nginx.conf.sigil` will need to be placed into the app source. The latest is available [here](https://raw.githubusercontent.com/dokku/dokku/master/plugins/nginx-vhosts/templates/nginx.conf.sigil), though you may wish to get the one for your particular version of Dokku. Copy that file to `nginx.conf.sigil` in the root of your repository and commit it:

```shell
curl -L --output nginx.conf.sigil https://raw.githubusercontent.com/dokku/dokku/master/plugins/nginx-vhosts/templates/nginx.conf.sigil
git add nginx.conf.sigil
git commit -m "feat: vendor nginx.conf.sigil"
```

Next, add the following location block to the file. The are two locations that it can be added to, both after the `location /` block. The first block is for `http` support, while the latter is for `https` support. We can add it to both for simplicities sake:

```nginx
  location /echo {
    proxy_buffering off;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_pass http://{{ $.APP }}-ws;
  }
```

In the above `location` block, the path is set to `/echo`. This is the path that the `ws` process responds to requests on. If your path is something else, this can be changed.

!!! warning
    
    The `proxy_pass` line omits a trailing slash (`/`). This allows the request to flow to the `ws` process at `/echo`. If a trailing slash is added, then the request made to the `ws` process will be at `/`. Please see [this stackoverflow answer](https://stackoverflow.com/a/22759570/1515875) for more details on how trailing slashes work with proxy pass.

Once the `location` blocks are added, we can add the upstream block at the end of the file. The following upstream block assumes the `ws` process is listening on port `5000`, but this may be changed as appropriate.

```
upstream {{ $.APP }}-ws {
{{ if not $.DOKKU_APP_WS_LISTENERS }}
  server 127.0.0.1:65535; # force a 502
{{ else }}
{{ range $listeners := $.DOKKU_APP_WS_LISTENERS | split " " }}
{{ $listener_list := $listeners | split ":" }}
{{ $listener_ip := index $listener_list 0 }}
  server {{ $listener_ip }}:5000;{{ end }}
{{ end }}
}
```

Once the updates are made, commit the changes:

```shell
git add nginx.conf.sigil
git commit -m "feat: route /echo to ws process"
```

Note that we use the template variable `$.DOKKU_APP_WS_LISTENERS`, which maps to our `ws` process. If using a different process name, then the variable being listened to would be different. A few examples are below:

| process name   | variable                           |
|----------------|------------------------------------|
| `ws`           | `$.DOKKU_APP_WS_LISTENERS`         |
| `websocket`    | `$.DOKKU_APP_WEBSOCKET_LISTENERS`  |
| `web-socket`   | `$.DOKKU_APP_WEB_SOCKET_LISTENERS` |

One thing to note in the above nginx template snippet is the check for the variable `$.DOKKU_APP_WS_LISTENERS`. Without this check, a deploy that doesn't scale up the `ws` process will fail to produce a valid `nginx.conf` file, failing the deploy. The variable will only have a value with there are processes scaled up.

At this point, assuming the codebase in question is similar to the websocket-tutorial, we can deploy the app and scale up our `ws` process, allowing websocket connections to flow through to your non-web process.

```shell
git push dokku master
dokku ps:scale websocket-example ws=1
```
