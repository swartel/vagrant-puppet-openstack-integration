# Puppet top level file
#
# Roles and Env(ironments)
# (Idea from https://github.com/example42/puppet-example42)
#
# In this module there's usage of 2 Top Scope Variables:
#
# $::target_role - Identifies groups of nodes that have the same function
#           and general layout
#
# $::tier - Identifies the functional environment of the node
#           For example: dev, test, prod
# This is defined separated from Puppet's internal $environment variable,
# which may be used to define different "Puppet environments" and
# according to custom approaches may or may not be used to identify
# also functional environments.
#

case $::domain {
  /^vagrant.local/: {
    $tier = 'test'
  }
  default: {
    $tier = 'production'
  }
}

case $::hostname {
# puppet master
  /^puppet/: {
    $target_role = 'puppetserver'
  }

# puppet agent
  /^host/: {
    $target_role = 'allinone'
  }

# Default
  default: {
    $target_role = 'nothing'
  }
}
notify { "tier: $tier role: $target_role": }

include deployopenstack
