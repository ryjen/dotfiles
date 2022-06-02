# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version '>= 2.1.4'

BASE_IP ||= '192.168.'
PRIV_IP ||= '56.5'
PUB_IP ||= '1.15'

# setup a virtual box provider
def configure_virtualbox(node)
  node.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']
  node.customize ['modifyvm', :id, '--cpus', '1']
  node.customize ['modifyvm', :id, '--memory', '1024']
end

# setup a docker provider
def configure_docker(node)
  node.image = 'ubuntu'
  node.has_ssh = true
end

# setup providers
def configure_providers(node)
  node.vm.provider :virtualbox do |vb|
    configure_virtualbox(vb)
  end
  node.vm.provider :docker do |docker|
    configure_docker(docker)
  end
end

# configure a guest network
def configure_network(node, index)
  node.vm.network :private_network, ip: "#{BASE_IP}#{PRIV_IP}#{index}"
  node.vm.network :public_network, ip: "#{BASE_IP}#{PUB_IP}#{index}"
  return unless index == 1

  node.vm.network :forwarded_port, guest: 80, host: 8880
  node.vm.network :forwarded_port, guest: 443, host: 4443
  node.vm.network :forwarded_port, guest: 8080, host: 8080
end

# configure a guest box
def configure_guest(node, name, index)
  node.vm.hostname = name
  node.vm.box = 'ubuntu/focal64'
  node.vm.box_check_update = true
  node.vm.synced_folder '.', '/vagrant'
  configure_providers(node)
end

Vagrant.configure(2) do |config|
  name = "dotfiles-test"

  config.vm.define name do |node|
    configure_guest(node, name, 1)
  end
end