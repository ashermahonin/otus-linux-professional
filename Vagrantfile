# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  "inetRouter" => {
    networks: [
      { ip: "192.168.255.1", netmask: "255.255.255.252", adapter: 2, virtualbox__intnet: "inet-net" }
    ]
  },
  "centralRouter" => {
    networks: [
      { ip: "192.168.255.2", netmask: "255.255.255.252", adapter: 2, virtualbox__intnet: "inet-net" },
      { ip: "192.168.0.17", netmask: "255.255.255.240", adapter: 3, virtualbox__intnet: "central-transit" },
      { ip: "192.168.0.1", netmask: "255.255.255.240", adapter: 4, virtualbox__intnet: "central-directors" },
      { ip: "192.168.0.33", netmask: "255.255.255.240", adapter: 5, virtualbox__intnet: "central-hardware" },
      { ip: "192.168.0.65", netmask: "255.255.255.192", adapter: 6, virtualbox__intnet: "central-wifi" }
    ]
  },
  "office1Router" => {
    networks: [
      { ip: "192.168.0.18", netmask: "255.255.255.240", adapter: 2, virtualbox__intnet: "central-transit" },
      { ip: "192.168.2.1", netmask: "255.255.255.192", adapter: 3, virtualbox__intnet: "office1-dev" },
      { ip: "192.168.2.65", netmask: "255.255.255.192", adapter: 4, virtualbox__intnet: "office1-test" },
      { ip: "192.168.2.129", netmask: "255.255.255.192", adapter: 5, virtualbox__intnet: "office1-managers" },
      { ip: "192.168.2.193", netmask: "255.255.255.192", adapter: 6, virtualbox__intnet: "office1-hardware" }
    ]
  },
  "office2Router" => {
    networks: [
      { ip: "192.168.0.19", netmask: "255.255.255.240", adapter: 2, virtualbox__intnet: "central-transit" },
      { ip: "192.168.1.1", netmask: "255.255.255.128", adapter: 3, virtualbox__intnet: "office2-dev" },
      { ip: "192.168.1.129", netmask: "255.255.255.192", adapter: 4, virtualbox__intnet: "office2-test" },
      { ip: "192.168.1.193", netmask: "255.255.255.192", adapter: 5, virtualbox__intnet: "office2-hardware" }
    ]
  },
  "centralServer" => {
    networks: [
      { ip: "192.168.0.2", netmask: "255.255.255.240", adapter: 2, virtualbox__intnet: "central-directors" }
    ]
  },
  "office1Server" => {
    networks: [
      { ip: "192.168.2.2", netmask: "255.255.255.192", adapter: 2, virtualbox__intnet: "office1-dev" }
    ]
  },
  "office2Server" => {
    networks: [
      { ip: "192.168.1.2", netmask: "255.255.255.128", adapter: 2, virtualbox__intnet: "office2-dev" }
    ]
  }
}.freeze

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  MACHINES.each do |name, machine|
    config.vm.define name do |node|
      node.vm.hostname = name

      machine[:networks].each do |network|
        node.vm.network "private_network", **network
      end

      node.vm.provider "virtualbox" do |virtualbox|
        virtualbox.name = "otus-19-#{name}"
        virtualbox.memory = 1024
        virtualbox.cpus = 1
      end

      next unless name == "office2Server"

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/playbook.yml"
        ansible.limit = "all"
        ansible.groups = {
          "routers" => ["inetRouter", "centralRouter", "office1Router", "office2Router"],
          "network_nodes" => ["centralRouter", "office1Router", "office2Router", "centralServer", "office1Server", "office2Server"]
        }
      end
    end
  end
end
