vagrant-puppet-openstack-integration
====================================

#### Table of contents

1. [Overview - What is Vagrant Puppet OpenStack Integration for?](#Overview)
2. [Requirements - What do you need to start deploying your OpenStack?](#Requirements)
3. [Deploy your base puppet environment](#Puppet deployment)

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
You need at least a pool storage named *default* and started:

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
located at /srv/storage/boxes/debian-jessie64-8.2.0-kvm.box and built using
veewee (https://github.com/jedi4ever/veewee).
Note that your box requires a user vagrant with sudo privileges to ALL.

Puppet deployment
-----------------

In this project, vagrant data are stored in yaml files.
The main data file is *vagrant.yaml* that can be overriden by file placed under
*vagrant-hieradata* directory depending on the scenario you may use.

For example, the override allinone.yaml help us to deploy a puppet server and one agent node:

```bash
puppet_env: master
hosts:
  - name: puppet
    ip: 192.168.34.10
    memory: 2048
  - name: host1
    ip: 192.168.34.11
    cpu: 1
    memory: 2048
    puppet_version: '1.3.2'
```

Its filename *allinone* has been chosen not to intend to deploy a puppet server
and its agent itsef but to deploy a puppet server and another node called host1
that should receive both controller and compute OpenStack role in futher step of
this project.

Note that:
* puppet_version is not the binary version (puppet --version) but the
package version of puppetlabs PC1 repository.
* the puppet-server version is defined under vagrant.yaml at the top scope level.

Before running into vagrant, just export the override according to the scenario
we need to test:
```bash
export LOCAL_CONFIG=vagrant-hieradata/allinone.yaml
```

And let's rock !
```bash
vagrant up --no-parallel
```

If everything goes well, you should now have a puppet server 4.x including a puppetdb
server as required to use storeconfigs. Take a look at the dashboard:

http://puppet.vagrant.local:8080/pdb/dashboard/index.html

You will find 2 nodes in the population.

And a quick check on puppet server certification autority:

```bash
puppet cert list --all
+ "host1.vagrant.local"  (SHA256) 7B:21:56:7C:33:A4:94:83:B2:BA:32:CC:B0:1D:A5:C5:52:E4:CF:4A:F1:B2:A5:07:1D:F2:D6:17:77:7C:C7:C6
+ "puppet.vagrant.local" (SHA256) E6:89:12:53:D2:B2:CA:71:45:2B:DD:E5:50:F0:30:B5:60:FF:A3:F9:82:A7:E9:5B:DC:46:94:BD:0E:44:7E:29 (alt names: "DNS:puppet.vagrant.local", "DNS:puppet", "DNS:puppet.vagrant.local")
```


Work in progress so coming soon...
