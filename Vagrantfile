# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.require_version '>= 1.7.2'

require 'yaml'

# Just list vagrant mandatory plugins here
required_plugins = %w(vagrant-hostmanager)

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

DEFAULT_CONFIG = {
  :puppet_env => `git symbolic-ref --short -q HEAD | tr -d '\n'`,
}

def node_val(node, config, sym)
  name = sym.to_s
  node[name] || val(config, sym)
end

def val(config, sym)
  name = sym.to_s
  ENV[name] || ENV[name.upcase] || config[name]
end

def loadConfiguration()
  config_filename = ENV['CONFIG'] || 'vagrant.yaml'
  local_config_filename = ENV['LOCAL_CONFIG'] || 'local_vagrant.yaml'
  config_file = File.join( File.dirname(__FILE__), config_filename)
  local_config_file = File.join( File.dirname(__FILE__), local_config_filename)
  local_config = File.exist?(local_config_file) ? YAML::load_file(local_config_file) : {}

  # Overload default config with local config
  config = YAML.load_file(config_file)
  config.merge(DEFAULT_CONFIG)
  config.merge(local_config)
end

def checkForVagrantPlugins(plugins_list)
  # Install required vagrant plugins if necessary
  plugins_list.each do |plugin|
    need_restart = false
    unless Vagrant.has_plugin? plugin
      system "vagrant plugin install #{plugin}"
      need_restart = true
    end
    exec "vagrant #{ARGV.join(' ')}" if need_restart
  end
end

# Check parameters and plugins depending to the provider used
main_config = loadConfiguration()
provider = 'virtualbox'
has_provider_arg = ARGV.index {|s| s.include?('--provider')}

if ARGV.include?('--provider=libvirt') ||
  (!has_provider_arg &&
   ENV['VAGRANT_DEFAULT_PROVIDER'] == 'libvirt') ||
  (!has_provider_arg &&
   val(main_config, :provider) == 'libvirt')

  required_plugins << 'vagrant-libvirt'
  required_plugins << 'fog-libvirt'
  provider = 'libvirt'
end

if provider != 'virtualbox' && ARGV.include?('up')
  if not ARGV.include?('--no-parallel')
    puts "You really want the machine not to be started in parallel. Please rerun with --no-parallel argument. #{provider}"
    exit
  end
end

# Install mandatory plugins
checkForVagrantPlugins(required_plugins)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # local cache between host and vm
  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  # To prevent tty errors
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # Turn off default shared folders
  config.vm.synced_folder '.', '/vagrant', id: 'vagrant-root', disabled: true

  # Configure hostmanager
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  if provider == 'virtualbox'
    config.vm.provider :virtualbox do |virtualbox, override|
      # Every Vagrant virtual environment requires a box to build off of.
      # This box must have puppet 3.3.1 already installed
      override.vm.box = val(main_config, :image)

      # The url from where the 'config.vm.box' box will be fetched if it
      # doesn't already exist on the user's system.
      # uncomment as soon as the box is uploaded
      override.vm.box_url = "/srv/storage/boxes/#{val(main_config, :image)}.box"
    end
  end

  if provider == 'libvirt'
    config.vm.provider :libvirt do |libvirt, override|
      libvirt.driver = 'kvm'
      #libvirt.host = 'localhost'
      libvirt.connect_via_ssh = false
      libvirt.storage_pool_name = 'default'
      override.vm.box = val(main_config, :image)
      override.vm.box_url = "/srv/storage/boxes/#{val(main_config, :image)}-kvm.box"
    end
  end

  # Assume puppetmaster is first describe host
  master_name_fqdn = ''
  if val(main_config, :puppetmaster) &&
    (val(main_config, :puppetmaster).length > 0)
    master_name_fqdn = "#{val(main_config, :puppetmaster)}.#{val(main_config, :domain)}"
    puts "The puppetmaster is configured to #{master_name_fqdn}."
  else
    puts "No puppetmaster to configure."
  end

  ## Hosts configuration
  main_config['hosts'].each_with_index do |node, index|

    autostart = node_val(node, main_config, :autostart)
    config.vm.define node['name'], autostart: autostart do |client_config|
      # Set hostname to the VM
      client_config.vm.host_name = "#{node['name']}.#{val(main_config, :domain)}"
      shell_command = []

      if provider == 'libvirt'
        client_config.vm.provider :libvirt do |os_client, override|
          override.vm.network :private_network, ip: "#{node['ip']}",
            :libvirt__network_name => 'vagrant_private_network'
          os_client.memory = node_val(node, main_config, :memory)
          os_client.cpus = node_val(node, main_config, :cpu)
        end
      end
      if provider == 'virtualbox'
        client_config.vm.provider :virtualbox do |os_client, override|
          # Create a private network, which allows host-only access to the machine
          # using a specific IP.
          override.vm.network :private_network, ip: "#{node['ip']}"
          os_client.customize ['modifyvm', :id, '--memory', node_val(node, main_config, :memory)]
          os_client.customize ['modifyvm', :id, '--cpus', node_val(node, main_config, :cpu)]
        end
      end

      # Set parameter AptCatcher if set
      if val(main_config, :apt_cacher_url)
          shell_command <<
            "test -f /etc/apt/apt.conf.d/000apt-cacher-ng-proxy || \
            echo 'Acquire:http { Proxy \"#{val(main_config, :apt_cacher_url)}\"; };' > \
            /etc/apt/apt.conf.d/000apt-cacher-ng-proxy"
      end
      client_config.vm.provision :shell do |shell|
        shell.inline = shell_command.join(';')
      end

      # Provision : Bootstrap nodes
      if node['name'] == val(main_config, :puppetmaster)
        # Node puppetmaster - Masterless installation
        if val(main_config, :use_local_fs)
          client_config.vm.synced_folder '.', "/etc/puppetlabs/code/environments/#{val(main_config, :puppet_env)}", type: 'nfs'
        end
        client_config.vm.provision :shell do |shell|
          shell.path = 'bootstrap_puppetmaster.sh'
          shell.args = "#{node_val(node, main_config, :puppet_version)} #{val(main_config, :puppet_env)} #{val(main_config, :use_local_fs)}"
        end
      else
        # Standard node
        # Classic installation - connect to a Puppetmaster
        client_config.vm.provision :shell do |pp_install|
          pp_install.path = 'bootstrap_client.sh'
          pp_install.args = "#{node_val(node, main_config, :puppet_version)} #{val(main_config, :puppet_env)} \"#{master_name_fqdn}\""
        end
        # Masterless installation - replace previous provision system with this one
        if ! val(main_config, :puppetmaster) || val(main_config, :puppetmaster) == ''
          client_config.vm.synced_folder "hieradata/test", "/tmp/vagrant-hiera/", type: 'nfs'
          client_config.vm.provision :puppet do |pp_masterless|
            pp_masterless.manifest_file = "nodes.pp"
            pp_masterless.hiera_config_path = "hiera.yaml"
            pp_masterless.working_directory = "/tmp/vagrant-puppet"
            pp_masterless.module_path = ["modules", "sitemodules"]
            pp_masterless.synced_folder_type = 'nfs'
            pp_masterless.options = "--trace --yamldir /hieradata --verbose --debug"
          end
        end
      end
    end
  end
end
