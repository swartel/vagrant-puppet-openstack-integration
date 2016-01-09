#
class deployopenstack::hosts {
  host { 'localhost.localdomain':
    ensure       => 'present',
    ip           => $::ipaddress_lo,
    target       => '/etc/hosts',
    host_aliases => 'localhost',
  }
  host { $::fqdn:
    ensure       => 'present',
    ip           => $::ipaddress_eth0,
    target       => '/etc/hosts',
    host_aliases => $::hostname,
  }
}
