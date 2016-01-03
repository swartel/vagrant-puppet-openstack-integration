vagrant-puppet-openstack-integration
====================================

#### Table of contents

1. [Overview - What is Vagrant Puppet OpenStack Integration for?](#Overview)
2. [Requirements - What do you need to start deploying your OpenStack?](#Requirements)

Overview
--------

This aim of this project is to deploy your OpenStack ready for integration using
vagrant as a nice way to set up a scalable puppet environment.
All OpenStack puppet modules used here come from the official gerrit OpenStack
repository in view to stay as closed as possible to the OpenStack best effort
improvements.

Requirements
------------

This project has been developped and tested for Debian 7/8 and Ubuntu 14.04 and 
uses Vagrant (require_version '>= 1.7.2') as a starting point which requires a 
minimal set of plugins:

* fog-libvirt
* vagrant-cachier
* vagrant-hostmanager
* vagrant-kvm
* vagrant-libvirt
* vagrant-share

To retrieve and check the list of Vagrant plugins already installed:

```bash
vagrant plugin list
```

To install missing plugins:

```bash
vagrant plugin install fog-libvirt vagrant-cachier...
```

The only provider supported for the moment is libvirt.
To avoid switching accidentally from libvirt to another unsupported provider, 
just fix it in your ~/.bashrc or ~/.zshrc or whatever your shell is:

```bash
export VAGRANT_DEFAULT_PROVIDER="libvirt"
```

Ensure you get service libvirt-bin running.
You need at lesat a pool storage named *default* and started:

```bash
virsh pool-list
 Name                 State      Autostart
------------------------------------------
 default              active     yes
```

And a network named *vagrant_private_network*:

```bash
virsh net-list
 Name                    State      Autostart     Persistent 
-----------------------------------------------------------
 vagrant_private_network active     no            yes

virsh net-edit vagrant_private_network
<network ipv6='yes'>
  <name>vagrant_private_network</name>
  <uuid>c2db0b51-c935-4a86-b744-c4351105236b</uuid>
  <forward mode='nat'/>
  <bridge name='virbr6' stp='on' delay='0'/>
  <mac address='52:54:00:7f:ab:9f'/>
  <ip address='192.168.34.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.34.1' end='192.168.34.254'/>
    </dhcp>
  </ip>
</network>
```

Please refer to (http://wiki.libvirt.org/page/Networking) for more informations.

Finally you need to build your own kvm box. In this example, we use a box 
located at /srv/storage/boxes/debian-jessie64-8.2.0-kvm.box and built it using
veewee (https://github.com/jedi4ever/veewee).
Note that your box requires a user vagrant with sudo privileges to ALL.


Work in progress so coming soon...
