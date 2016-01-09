#Default haveged profile
class deployopenstack::profile::default::haveged {

  # The Userland Solution for Populating Entropy Pools
  case $::lsbdistcodename {
    'squeeze': {
      # iTo install this package, you'll need to install squeeze-backport repository
    }
    default: {
      package { 'haveged':
        ensure => installed,
      }
    }
  }
}
