---
template: main.html
title: Tutorials
search:
  exclude: true
---

<style>
  /*hide the duplicate tutorials heading*/
  .md-nav__item--nested .md-nav__item--active .md-nav__link:first-of-type {
    display:  none;
  }
  /*drop icon*/
  .md-nav__link .md-nav__icon.md-icon {
    display:  none;
  }
  .md-sidebar--secondary:not([hidden]) {
    visibility: hidden;
  }
  /*remove padding on tutorials posts*/
  .md-nav__item--nested .md-nav__item--nested .md-nav .md-nav__list .md-nav__item {
    padding:  0;
  }
</style>

# Tutorials

## [Inter-app Communication in Dokku]

Dokku supports cross-container and cross-app communication via custom docker networks

  [:octicons-arrow-right-24: Continue reading][Inter-app Communication in Dokku]

  [Inter-app Communication in Dokku]: network/inter-app-communication.md

## [Connecting to network processes running directly on the host]

Dokku supports connecting deployed applications to processes that expose network connections on the host.

  [:octicons-arrow-right-24: Continue reading][Connecting to network processes running directly on the host]

  [Connecting to network processes running directly on the host]: network/connect-to-host-processes.md

## [Deploying to a Dokku-managed k3s cluster]

Dokku natively supports both single and multi-server deployments. This tutorial shows how to manage both with k3s under the hood.

  [:octicons-arrow-right-24: Continue reading][Deploying to a Dokku-managed k3s Cluster]

  [Deploying to a Dokku-managed k3s Cluster]: other/deploying-to-k3s.md

## [Using Websockets with Nginx]

Running a sidecar process to serve websocket requests can be done by following this tutorial.

  [:octicons-arrow-right-24: Continue reading][Using Websockets with Nginx]

  [Using Websockets with Nginx]: other/using-websockets-in-dokku.md

## [Deploying an image without a registry]

Deploying an image does not always require a remote registry, as shown in this short tutorial.

  [:octicons-arrow-right-24: Continue reading][Deploying an image without a registry]

  [Deploying an image without a registry]: other/deploying-an-image-without-a-registry.md

## [Creating a Datastore plugin]

Ever wanted to write a datastore plugin? This tutorial shows how we create official datastore plugins.

  [:octicons-arrow-right-24: Continue reading][Creating a Datastore plugin]

  [Creating a Datastore plugin]: plugins/creating-a-datastore-plugin.md

## [Automating Dokku Application Setup with Ansible]

This tutorial goes through the process of provisioning an app via ansible.

  [:octicons-arrow-right-24: Continue reading][Automating Dokku Application Setup with Ansible]

  [Automating Dokku Application Setup with Ansible]: automation/automating-dokku-setup.md

## [Run on an External Volume]

In order to leverage cloud-provider facilities like _attachable volumes_, (_a.k.a. block storage_)
the following is an easy tutorial to achieve Dokku runs on them.

  [:octicons-arrow-right-24: Continue reading][Run on an External Volume]

  [Run on an External Volume]: other/run-on-external-volume.md

## [Deploying Gogs to Dokku]

Hot off the release of Dokku 0.6.3, here is a sweet tutorial made possible by the new port handling feature of Dokku.

  [:octicons-arrow-right-24: Continue reading][Deploying Gogs to Dokku]

  [Deploying Gogs to Dokku]: apps/deploying-gogs-to-dokku.md
