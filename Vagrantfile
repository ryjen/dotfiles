# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version '>= 2.1.4'

# setup a docker provider
def configure_docker(node)
  node.image = 'ubuntu'
  #node.has_ssh = true
end

# setup providers
def configure_providers(node)
  node.vm.provider :docker do |docker|
    configure_docker(docker)
  end
end

# configure a guest box
def configure_guest(node, name, index)
  #node.vm.hostname = name
  #node.vm.box = 'hashicorp/bionic64'
  #node.vm.box_check_update = true
  #node.vm.synced_folder '.', '/vagrant'
  configure_providers(node)
end

Vagrant.configure(2) do |config|
  config.vm.hostname = "ubuntu"
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "docker" do |d, override|
    override.vm.box = nil
    d.image = "rofrano/vagrant-provider:ubuntu"
    d.remains_running = true
    d.has_ssh = true
    d.privileged = true
    d.volumes = ["/sys/fs/cgroup:/sys/fs/cgroup:rw"]
    d.create_args = ["--cgroupns=host"]
  end
  #name = "dotfiles-test"

  #config.vm.define name do |node|
  #  configure_guest(node, name, 1)
  #end
end