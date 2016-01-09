#!/bin/bash

if [ "$#" -lt 1 -o "$#" -gt 3 ]; then
    echo "Wrong argument number!"
    echo "Usage: ./bootstrap_puppetmaster.sh <puppet_pin_version> <puppet_environment> <use_local_fs>"
    echo "Ex: For puppet 4.0 or newer ./bootstrap_puppetmaster.sh 2.2.1 production true"
    exit 1
fi

PUPPET_PIN_VERSION=$1
PUPPET_ENV=${2:-production}
PUPPET_LOCALFS=${3:-false}

PUPPET_ENV_PATH=/etc/puppetlabs/code/environments

echo "Bootstrapping puppet/r10k install (version ${PUPPET_PIN_VERSION} with env ${PUPPET_ENV} and localfs ${PUPPET_LOCALFS})"

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
  fi
}

function install_puppet() {
  echo "Updating apt cache"
  apt-get update > /dev/null

  echo "Installing puppetserver(${PUPPET_PIN_VERSION}) and git"
  apt-get install -y puppetserver=${PUPPET_PIN_VERSION}-1puppetlabs1 git > /dev/null 2>&1

  echo "Update jvm memory allocation to: -Xms512m -Xmx512m"
  sed -i "s/-Xms2g -Xmx2g/-Xms512m -Xmx512m/" /etc/default/puppetserver

  echo "Updating puppet.conf server and dns_alt_names to $(hostname -f)"
  cat > /etc/puppetlabs/puppet/puppet.conf <<EOF
[master]
  vardir = /opt/puppetlabs/server/data/puppetserver
  logdir = /var/log/puppetlabs/puppetserver
  rundir = /var/run/puppetlabs/puppetserver
  pidfile = /var/run/puppetlabs/puppetserver/puppetserver.pid
  codedir = /etc/puppetlabs/code
  storeconfigs = true
  storeconfigs_backend = puppetdb
  reports = store,puppetdb

[main]
  dns_alt_names = $(hostname),$(hostname -f)
  environment = ${PUPPET_ENV}
[agent]
  server = $(hostname -f)
EOF

  echo "Updating jruby-puppet.use-legacy-auth-conf to false (default: true)"
  sed -i "s/#use-legacy-auth-conf: false/use-legacy-auth-conf: false/" /etc/puppetlabs/puppetserver/conf.d/puppetserver.conf

  echo "Restarting puppetserver daemon"
  service puppetserver restart

  #Be sure puppetmaster is running before puppetdb installation
  if [ $? -eq 0 ]; then
    echo "Installation puppetdb puppetdb-termini"
    apt-get install -y puppetdb puppetdb-termini > /dev/null 2>&1
    /opt/puppetlabs/bin/puppetdb ssl-setup
    cat > /etc/puppetlabs/puppet/routes.yaml << EOF
---
  
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOF
    echo "Configuring puppetdb"
    cat > /etc/puppetlabs/puppet/puppetdb.conf << EOF
[main]
server_urls = https://$(hostname -f):8081
EOF
    chown -R puppet:puppet $(/opt/puppetlabs/bin/puppet config print confdir)

    #/!\ Enable unsecured puppetdb dashboard
    #http://puppet.vagrant.local:8080/pdb/dashboard/index.html
    sed -i "s/# host = <host>/host = 0.0.0.0/" /etc/puppetlabs/puppetdb/conf.d/jetty.ini

    #Need to restart services
    echo "Restarting puppetdb daemon"
    service puppetdb restart
    echo "Restarting puppetserver daemon"
    service puppetserver restart
  fi

  echo "Adding puppet's excutables to PATH"
  export PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
  #if needed for all users
  echo "PATH=\"/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH\"" | tee -a /etc/environment > /dev/null
  #Require for sudo
  echo "PATH=\"/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH\"" | tee -a /root/.bashrc > /dev/null
}

function hiera_setup() {
  echo "Creating hiera.yaml"

  PUPPET_HIERA=/etc/puppetlabs/code/hiera.yaml

  # Basic hiera config (bootstrap)
  cat > ${PUPPET_HIERA} <<EOF
---
:backends:
  - yaml

:logger: console

:hierarchy:
  - "%{::tier}/nodes/%{::fqdn}"
  - "%{::tier}/roles/%{::target_role}"
  - "%{::tier}/common"

:yaml:
EOF

  echo "  :datadir: ${PUPPET_ENV_PATH}/%{::environment}/hieradata" >> ${PUPPET_HIERA}
}


function r10k_setup() {
  if ! [ -d /var/cache/r10k ] ; then
    mkdir /var/cache/r10k
    chown puppet:puppet /var/cache/r10k
  fi

  echo "Installing r10k gem"
  local R10K_PATH=/etc/puppetlabs/r10k
  if $(/opt/puppetlabs/puppet/bin/gem list r10k -i); then
    echo "r10k gem is already installed"
  else
    /opt/puppetlabs/puppet/bin/gem install r10k --no-ri --no-rdoc > /dev/null 2>&1
  fi

  echo "Creating r10k.yaml"
  if ! [ -d ${R10K_PATH} ]; then
    mkdir -p ${R10K_PATH}
  fi

  cat > ${R10K_PATH}/r10k.yaml <<EOF
---
:cachedir: /var/cache/r10k
:sources:
  :local:
    remote: https://github.com/swartel/vagrant-puppet-openstack-integration.git
    basedir: $PUPPET_ENV_PATH
EOF
}

function r10k_deploy() {
  local penv="$PUPPET_ENV"
  if [ "$PUPPET_LOCALFS" == "true" ]; then
    echo "Fetching modules with r10k"
    cd $PUPPET_ENV_PATH/$penv/
    # We cannot run this as puppet user because $PUPPET_ENV_PATH/$penv/ is an NFS mount point
    # and we will not have the right privileges to create modules directory.
    r10k puppetfile install
  else
    echo "Deploying with r10k for environment: $penv"
    if [ -d $PUPPET_ENV_PATH ] ; then
      chown puppet:puppet $PUPPET_ENV_PATH
    fi
    sudo -u puppet /bin/bash -c "cd \$PUPPET_ENV_PATH ; r10k deploy environment $penv --puppetfile"
  fi
}

function puppet_apply() {
  local penv="$PUPPET_ENV"

  # We must be root to run puppet apply to setup puppet master
  echo "Performing first puppet run with environment: $penv"
  puppet apply $PUPPET_ENV_PATH/$penv/manifests \
    --modulepath=$PUPPET_ENV_PATH/$penv/modules:$PUPPET_ENV_PATH/$penv/sitemodules \
    --environment $penv \
    --debug
}

function setup_role_via_facter() {
  cat > /opt/puppetlabs/facter/facts.d/puppet_role.txt << EOF
puppet_role=puppetserver
EOF
}

#TODO: Ensure vagrant user exists and has sudo privileges
function check_vagrant_sudo() {
  if [ -f /etc/sudoers.d/vagrant ] ; then
    chmod 0440 /etc/sudoers.d/vagrant
  fi
}

# Ensure locale is set en_US.UTF-8 for puppetmaster
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

function main() {
  aptsources_setup
  check_vagrant_sudo
  setup_locale
  install_puppet
  hiera_setup
  setup_role_via_facter
  r10k_setup
  r10k_deploy
  puppet_apply
}

if [[ "$EUID" -ne "0" ]]; then
echo "This script must be run as root." >&2
  exit 1
fi

main
