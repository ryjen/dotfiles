# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version '>= 2.1.4'

Vagrant.configure(2) do |config|

  config.vm.define "dotfiles-test" do |node|
    node.vm.hostname = "dotfiles-test"
    node.vm.synced_folder ".", "/vagrant"
    node.vm.box = nil

    node.vm.provider "docker" do |guest|
      guest.image = "rofrano/vagrant-provider:ubuntu"
      guest.remains_running = true
      guest.has_ssh = true
      guest.privileged = true
      guest.volumes = ["/sys/fs/cgroup:/sys/fs/cgroup:rw"]
      guest.create_args = ["--cgroupns=host"]
    end
  end
end