#Role deployopenstack puppet server
class deployopenstack::role::puppetserver {

  include deployopenstack::profile::default
  include deployopenstack::profile::puppetserver
}
