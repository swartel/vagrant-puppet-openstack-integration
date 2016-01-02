#!/bin/bash
#
# arg1: puppet apt pin version to install (deb 1.3.2 -> puppet 4.3.2)
# arg2: puppet environment name
# arg3: puppet server name
#
# Based on a script from Hashicorp
# https://raw.githubusercontent.com/hashicorp/puppet-bootstrap/master/debian.sh
#
PUPPET_PIN_VERSION=$1
PUPPET_ENV=${2:-production}
PUPPET_SERVER=${3:-puppet}

if [[ $# -ne 3 ]]; then
    echo "Wrong argument number!"
    echo "Usage: ./bootstrap_client.sh <puppet_pin_version> <puppet_environment> <puppet_server>"
    echo "Ex: ./bootstrap_client.sh 1.3.2 develop puppet"
    exit 1
fi

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

function aptsources_setup() {
  local distro=`lsb_release -i | awk '{print $3}'`
  local release=`lsb_release -c | awk '{print $2}'`
  if [[ "${distro}" == "Ubuntu" || "${distro}" == "Debian" ]]
  then
    echo "Enable apt repository"
    wget -q https://apt.puppetlabs.com/puppetlabs-release-pc1-${release}.deb && \
    dpkg -i puppetlabs-release-pc1-${release}.deb

    if [ -f /etc/apt/sources.list.d/puppetlabs-pc1.list ]; then
      echo "Nothing to do: Puppetlabs repo already exists"
    else
      echo "Something goes wrong during deb installation of puppetlab repository"
      exit 1
    fi
  else
    echo "Unsupported distro ${distro}/${release}"
    exit 1
  fi
}

#TODO: Ensure vagrant user exists and has sudo privileges
function check_vagrant_sudo() {
  if [ -f /etc/sudoers.d/vagrant ] ; then
    chmod 0440 /etc/sudoers.d/vagrant
  fi
}

# Ensure locale is set en_US.UTF-8 for puppet agent
function setup_locale() {
  if [ ! -x /usr/sbin/locale-gen ] ; then
     apt-get install -y locales
  fi
  grep '^en_US.UTF-8' /etc/locale.gen > /dev/null || echo  en_US.UTF-8 UTF-8 >> /etc/locale.gen
  /usr/sbin/locale-gen en_US.utf-8

  if grep 'LANG="en_US.UTF-8"' /etc/default/locale >/dev/null; then
    echo "en_US.UTF-8 is properly set"
  else
    update-locale 'LANG="en_US.UTF-8"'
  fi

  export LANGUAGE=en_US.utf8
  export LC_ALL=en_US.utf8
  export LANG=en_US.utf8
}

function install_puppet() {
  local release=`lsb_release -c | awk '{print $2}'`

  echo "Updating apt cache"
  apt-get update > /dev/null

  if $PUPPET_V4; then
    echo "Installing puppet agent(${PUPPET_PIN_VERSION})"
    apt-get install -y puppet-agent=${PUPPET_PIN_VERSION}-1${release} > /dev/null 2>&1
  fi

  # Set Default Puppet Environment with Current Branch
  echo "Set Puppet default environment:${PUPPET_ENV}"
  cat >> /etc/puppetlabs/puppet/puppet.conf <<EOF
[agent]
environment=${PUPPET_ENV}
EOF

  echo "Adding puppet's excutables to PATH"
  export PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
  #if needed for all users
  echo "PATH=\"/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH\"" | tee -a /etc/environment > /dev/null
  #Require for sudo
  echo "PATH=\"/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH\"" | tee -a /root/.bashrc > /dev/null
}

function main() {
  aptsources_setup
  check_vagrant_sudo
  setup_locale
  install_puppet
}

# This bootstraps Puppet on Debian
set -e

main

echo "Launching puppet :"
/opt/puppetlabs/bin/puppet agent --test --debug || exit 0
