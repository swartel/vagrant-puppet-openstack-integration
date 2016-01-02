# Default node profile.
class deployopenstack::profile::default {

  #include deployopenstack::profile::default::motd
  include deployopenstack::profile::default::haveged
}
