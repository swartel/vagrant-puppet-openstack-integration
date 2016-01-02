# == Class: deployopenstack
#
# This class defines organization for all Openstack nodes and the puppetserver itself.
#
# === Authors
#
# Author Stephane Wartel <stephane@wartel.fr>
#
# === Copyright
#
# Copyright 2015 Stephane Wartel
#
class deployopenstack {

  # Include Role classes ($role variable must be set at top scope)
  include "deployopenstack::role::${::target_role}"
}
