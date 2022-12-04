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

## [Creating a Datastore plugin]

Ever wanted to write a datastore plugin? This tutorial shows how we create official datastore plugins.

  [:octicons-arrow-right-24: Continue reading][Creating a Datastore plugin]

  [Creating a Datastore plugin]: plugins/creating-a-datastore-plugin.md

## [Automating Dokku Application Setup with Ansible]

This tutorial goes through the process of provisioning an app via ansible.

  [:octicons-arrow-right-24: Continue reading][Automating Dokku Application Setup with Ansible]

  [Automating Dokku Application Setup with Ansible]: automation/automating-dokku-setup.md

## [Deploying Gogs to Dokku]

Hot off the release of Dokku 0.6.3, here is a sweet tutorial made possible by the new port handling feature of Dokku.

  [:octicons-arrow-right-24: Continue reading][Deploying Gogs to Dokku]

  [Deploying Gogs to Dokku]: apps/deploying-gogs-to-dokku.md
