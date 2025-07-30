---
title:  "Automating Dokku Application Setup with Ansible"
date:   2018-06-10 16:46:01 -0400
categories: general
tags:
  - dokku
  - provisioning
  - automation
---

When you deploy an app with Dokku, a common workflow is to create an app on `git push`:

```bash
git remote add dokku dokku@dokku.me:app
git push dokku master
```

This works relatively well, and most folks then stumble through an initial app deploy/configuration cycle. In some cases, a user will create a script to encompass their workflow, or update some document to contain all the commands that were found necessary. However, this fails in at least the following two cases:

- The existing server fails in some way, and a new server must be provisioned to quickly service all requests.
- You need to replicate your deployment process on multiple servers/for multiple services.

We'll evaluate two patterns to solve these problems, both of which are enabled by Dokku's porcelain interfaces.

> If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.

### Running Code on Server Boot

Regardless of whether this is for a single replacement server, or if it is for a series of servers, running code to _provision_ Dokku and necessary applications at boot time is ideal. Doing so will allow us to reduce the amount of time it takes to recover from service failure, as well as make it easier to do this on a fleet of servers. To this end, we can utilize **User Data**.

"User Data" is a bit of configuration that can be run by a process called `cloud-init`. You should consider `cloud-init` to be the defacto server initialization tool for cloud servers; many popular server providers support it, such as Amazon Web Services, Azure, Digital Ocean, Google Cloud Provider, Linode, etc. Most folks provide user-data in bash script format, but there are many different modules to integrate with `cloud-init`. As an example, our own docs for Dreamhost support provide installation instructions in `yaml` format.

Here is  the simplest user-data for installing Dokku:

```bash
#!/bin/bash
wget https://raw.githubusercontent.com/dokku/dokku/master/bootstrap.sh
sudo bash bootstrap.sh
```

Cloud providers generally have a way to specify user data for either a single server or a set of servers being launched, though the method is different depending on the provider. If your provider does not support user data, our recommendation is to switch to one that does.

### ~~Creating~~ Provisioning an app automatically

Taking this further, lets automatically create an app and configure it for deployment when a server starts


```bash
#!/bin/bash
wget https://raw.githubusercontent.com/dokku/dokku/master/bootstrap.sh
sudo bash bootstrap.sh

export APP_NAME="node-js-app"
dokku apps:exists "$APP_NAME" || dokku apps:create "$APP_NAME"
dokku config:set "$APP_NAME" KEY=value
```

Neat! One thing missing is the initial git clone, which would put our app into service. We can do that with the clone plugin:

```bash
dokku plugin:install https://github.com/crisward/dokku-clone.git clone
dokku clone "$APP_NAME" git@github.com:heroku/node-js-sample.git
```

> We'll be offering something even fancier soon, but props to Cris Ward for maintaining such a useful plugin!

You now have a fully provisioned app on a new server on server boot. Your application downtime with this methodology decreases signficantly, and in many cases, this is enough to keep your business running.

> For folks using Dokku plugins for datastores, restoring service when all your data was stored on a non-existent server is a longer conversation with no easy solutions. At this time, none of the datastore plugins directly support running in HA mode, though this is something worth investigating. At this time, using managed datastore providers such as AWS RDS, CloudAMQP, etc. are the suggested methods for having HA datastore solutions.

### A brief introduction to Configuration Management

Some of our users may be provisioning quite a few apps to a server, or the same server many times, or even managing a dozen servers for various clients. How do you handle that without a ton of bespoke bash scripts? How do you provision new applications without a tangle of `if` statements, in a DRY way? There are a few answers, but one common answer is to use a configuration management tool

Configuration management tools provide common libraries and patterns for organizing server automation code. There are quite a few different tools in the config management space, but the one we're going show off is Ansible.


Ansible requires python to run on a server. Assuming we're on an Ubuntu-based server, the following are roughly the installation instructions:

```bash
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
```

Ansible provides an abstraction for executing python modules by writing small bits of yaml. Here is an example for running ansible against the local server. Place the following in a file called `dokku.yml`

```yaml
---
- hosts: dokku
  tasks:
  - name: dokku repo
    apt_repository:
      filename: dokku
      repo: 'deb https://packagecloud.io/dokku/dokku/ubuntu/ {{ ansible_lsb.codename|lower }} main'
      state: present

    - name: install dokku
      apt:
        pkg: dokku
        state: installed
        update_cache: true
```

The above invokes python modules that takes the above as configuration and:

- creates an apt repository file for dokku
- ensures dokku is installed, updating the apt cache if apt isn't aware of it

To run the above, we'll need to create a `hosts` file. I've created a `dokku` group with the IP of the server I'm going to target.

```ini
[dokku]
127.0.0.1
```

Now that everything is setup, we can just run the following to execute our provisioning code:

```shell
ansible-playbook -i hosts -s dokku.yml
```

### Provisioning many Dokku apps/servers with Ansible

Now that we have a bare minimum ansible setup, we can iterate on this to provision actual Dokku applications. The following will create an app if it does not exist

```yaml
---
- hosts: dokku
  tasks:
    - name: does the node-js-app app exist
      shell: dokku apps:exists node-js-app
      register: app_exists
      ignore_errors: True

    - name: create an app
      shell: dokku apps:create node-js-app
      when: app_exists.rc == 1
```

This is pretty good so far, and uses the built-in `shell` Ansible libraries to do heavy lifting. However, the following would be much better:

```yaml
---
- hosts: dokku
  tasks:
    - name: dokku apps:create node-js-app
      dokku_app:
        app: node-js-app
```

The above would use a custom `dokku_app` Ansible library for provisioning applications, building upon the porcelain we covered previously.

> For our patreon followers, the code for the `dokku_app` library will be made available, as well as future plans around Ansible integration.

### Combining the methods into one

Assuming we have a repository with our server provisioning code - the yaml and hosts files - we can use the following user-data for automatically setting up a dokku server on boot.

```bash
#!/bin/bash

# install ansible
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible git

# clone your infra repo
git clone git@example.git:infra /tmp/infra

# provision the server
pushd /tmp/infra > /dev/null
ansible-playbook -i hosts -s dokku.yml
```

### Going Further

Once you have an `infra` repository containing the provisioning scripts for your servers, the next step is to do all Dokku configuration from this repository. This helps ensure migrating to a new server is as painless as possible, making service restoration a breeze.

---

If you're using Dokku - especially for commercial purposes - consider donating to project development via [Github Sponsors](https://github.com/sponsors/dokku), [OpenCollective](https://opencollective.com/dokku), or [Patreon](https://www.patreon.com/dokku). Funds go to general development, support, and infrastructure costs.
