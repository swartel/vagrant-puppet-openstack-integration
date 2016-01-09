#Role openstack allinone
class deployopenstack::role::allinone {

  include deployopenstack::profile::default
  include deployopenstack::profile::puppetagent
}
