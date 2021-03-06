#
# Specification of Virtual Machines managed by Vagrant.
# This script supports VirtualBox and HyperV providers.
# Machines should be specified in Vagranthosts.yaml file.
# Vagranthosts.yaml files has got documentation embedded in comments.
# Behaviour of this script is also documented in comments below.
#

#
# Load machines specification
#
require 'yaml'
curr_dir  = File.dirname(File.expand_path(__FILE__))
machines    = YAML.load_file("#{curr_dir}/Vagranthosts.yaml")

#
# Assert vagrant setup
#
Vagrant.require_version '>= 1.8.6', '!= 1.8.5'
def validate_plugins
  required_plugins = [
    'vagrant-hostmanager',
    'vagrant-proxyconf'
  ]
  missing_plugins = []

  required_plugins.each do |plugin|
    unless Vagrant.has_plugin?(plugin)
      missing_plugins << "The '#{plugin}' plugin is required. Install it with 'vagrant plugin install #{plugin}'"
    end
  end

  unless missing_plugins.empty?
    missing_plugins.each { |x| STDERR.puts x }
    return false
  end

  true
end

validate_plugins || exit(1)

#
# Provision machines
#
Vagrant.configure(2) do |config|
  #
  # Enable hostname resolution by machine name via /etc/hosts files.
  # 'getent' command (in contrast with nslookup) takes into account /etc/hosts file
  #  > getent hosts `hostname` | awk '{print $1}'.
  #
  # vagrant-hostmanager plugin places correct /etc/hosts files
  # https://github.com/devopsgroup-io/vagrant-hostmanager
  config.hostmanager.enabled = true
  config.hostmanager.ignore_private_ip = false

  # some variables for automated static IP address generation
  internal_subnet = nil

  machines.each do |name, machine|
    config.vm.define name do |s|
        #
        # Define image to be used to create a VM
        # Note: for portability it is recommended to pick generic image,
        # which has got versions for both VirtualBox and HyperV providers.
        #
        s.vm.box = machine['box'] || "generic/ubuntu1604"
        s.ssh.forward_agent = true
        s.vm.hostname = "#{name}"

        #
        # Configure hypervisor specific settings
        #
        s.vm.provider "virtualbox" do |vb, override|
            vb.name = s.vm.hostname
            vb.cpus = machine['cpus'] || 1
            vb.memory = machine['memory'] || 2048
            vb.gui = false

            # VirtualBox requires static IP address defined.
            # Static IP address is preserved when VM is rebooted.
            # IP address is automatically generated from the machine name;
            # it may not always work (i.e. may produce conflicting addresses),
            # but it is good enough as it is consistent result for the same machine name.
            if !internal_subnet
                internal_subnet = "#{name}".ord % 0xFF
            end
            machine_id = "#{name}".sum % 0xFF
            override.vm.network "private_network", ip: "192.168.#{internal_subnet}.#{machine_id}", netmask: "255.255.255.0", auto_config: true

            # Disable DHCP client configuration for NAT interface
            vb.auto_nat_dns_proxy = false
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
        end
        s.vm.provider "hyperv" do |hv, override|
            hv.vmname = s.vm.hostname
            hv.cpus = machine['cpus'] || 1
            hv.memory = machine['memory'] || 2048

            # Hyper-V assigns some available IP address automatically for each machine.
            # It seems the address is preserved when VM is rebooted.
            # Vagrant does not support network management for HyperV,
            # so fixed IP address can not be assigned.
            # However, it is important to define the name of the Internal Virtual Switch,
            # so vagrant does not promt interactively which one to use AND hostmanager plugin works.
            # Note: it is expected that the 'Internal'-named switch is created manually once.
            override.vm.network "private_network", bridge: "Internal"
        end
        # Remove loopback host alias that conflicts with vagrant-hostmanager
        # https://dcosjira.atlassian.net/browse/VAGRANT-15
        s.vm.provision :shell, inline: "sed -i'' '/^127.0.0.1\\t#{s.vm.hostname}\\t#{name}$/d' /etc/hosts"

        #
        # Enable port forwarding if it is specified in the configuration.
        #
        # HyperV:
        #   This feature is not yet supported by Vagrant
        #
        # VirtualBox:
        #   This feature is fully supported
        #
        if machine.has_key?('forwarded_port')
          s.vm.network "forwarded_port", guest: (machine['forwarded_port']['guest'] || 80), host: (machine['forwarded_port']['host'] || 80)
        end

        #
        # Configure proxy settings automatically
        #
        if ENV.has_key?('http_proxy') || ENV.has_key?('HTTP_PROXY')
            s.proxy.http = ENV['http_proxy'] || ENV['HTTP_PROXY']
            s.proxy.https = ENV['http_proxy'] || ENV['HTTP_PROXY']
        end
        if ENV.has_key?('https_proxy') || ENV.has_key?('HTTPS_PROXY')
            s.proxy.https = ENV['https_proxy'] || ENV['HTTPS_PROXY']
        end
        if ENV.has_key?('no_proxy') || ENV.has_key?('NO_PROXY')
            s.proxy.no_proxy = ENV['no_proxy'] || ENV['NO_PROXY']
        end

        #
        # Enable current and parent folder synchronization if enabled in the configuration.
        # The current host folder becomes accessible as /vagrant on the guest VM.
        # The parent host folder becomes accessible as /projects on the guest VM.
        #
        # HyperV:
        #   Uses SMB for two-way synchronization. This prompts for password to be typed interactively.
        #
        # VirtualBox:
        #   Uses native for VirtualBox two-way synchronization. Works seamlesly without passwords.
        #
        if machine['synced_folder']
          s.vm.synced_folder ".", "/vagrant"
        end
        if machine['synced_folder_projects']
          s.vm.synced_folder "..", "/projects"
        end

        #
        # Set toogle for development mode
        #
        if ENV.has_key?('development_mode') || ENV.has_key?('DEVELOPMENT_MODE')
            s.vm.provision :shell, inline: "echo \"export DEVELOPMENT_MODE=true\" >> ~/.profile"
        end

        #
        # Provision every file from the configuration
        #
        if machine['files']
            machine['files'].each do |file|
                s.vm.provision "file", source: "#{file}", destination: "/tmp/#{file}"
            end
        end

        #
        # Provision every command from the configuration
        #
        if machine['commands']
            machine['commands'].each do |command|
                s.vm.provision :shell, inline: "#{command}"
            end
        end
    end
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

end
