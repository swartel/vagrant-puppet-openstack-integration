# Puppet agent profile.
class deployopenstack::profile::puppetagent {

  class { '::puppet':
    agent                       => hiera('puppet::agent'),
    autosign                    => hiera('puppet::autosign'),
    codedir                     => hiera('puppet::codedir'),
    logdir                      => hiera('puppet::logdir'),
    port                        => hiera('puppet::port'),
    puppetmaster                => hiera('puppet::puppetmaster'),
    rundir                      => hiera('puppet::rundir'),
    runinterval                 => hiera('puppet::runinterval'),
    server                      => hiera('puppet::server'),
    server_foreman              => hiera('puppet::server_foreman'),
    server_implementation       => hiera('puppet::server_implementation'),
    service_name                => hiera('puppet::service_name'),
    splay                       => hiera('puppet::splay'),
    splaylimit                  => hiera('puppet::splaylimit'),
    vardir                      => hiera('puppet::vardir'),
  }
}
