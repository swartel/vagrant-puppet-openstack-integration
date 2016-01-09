# Puppetmaster profile.
class deployopenstack::profile::puppetserver {

  class { '::puppet':
    agent                       => hiera('puppet::agent'),
    autosign                    => hiera('puppet::autosign'),
    codedir                     => hiera('puppet::codedir'),
    hiera_config                => hiera('puppet::hiera_config'),
    logdir                      => hiera('puppet::logdir'),
    port                        => hiera('puppet::port'),
    rundir                      => hiera('puppet::rundir'),
    runinterval                 => hiera('puppet::runinterval'),
    server                      => hiera('puppet::server'),
    server_envs_dir             => hiera('puppet::server_envs_dir'),
    server_external_nodes       => '',
    server_foreman              => hiera('puppet::server_foreman'),
    server_implementation       => hiera('puppet::server_implementation'),
    server_jvm_min_heap_size    => hiera('puppet::server_jvm_min_heap_size'),
    server_jvm_max_heap_size    => hiera('puppet::server_jvm_max_heap_size'),
    server_jvm_extra_args       => hiera('puppet::server_jvm_extra_args'),
    server_passenger            => hiera('puppet::server_passenger'),
    server_reports              => hiera('puppet::server_reports'),
    server_storeconfigs_backend => hiera('puppet::server_storeconfigs_backend'),
    server_ssl_dir              => hiera('puppet::server_ssl_dir'),
    service_name                => hiera('puppet::service_name'),
    splay                       => hiera('puppet::splay'),
    splaylimit                  => hiera('puppet::splaylimit'),
    vardir                      => hiera('puppet::vardir'),
  }
}
