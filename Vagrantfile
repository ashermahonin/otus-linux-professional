# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "inetRouter" do |router|
    router.vm.hostname = "inet-router"
    router.vm.network "private_network",
                      ip: "192.168.255.1",
                      netmask: "255.255.255.252",
                      virtualbox__intnet: "otus21-transit"
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-21-inet-router"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "centralRouter" do |router|
    router.vm.hostname = "central-router"
    router.vm.network "private_network",
                      ip: "192.168.255.2",
                      netmask: "255.255.255.252",
                      virtualbox__intnet: "otus21-transit"
    router.vm.network "private_network",
                      ip: "192.168.100.1",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus21-servers"
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-21-central-router"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "centralServer" do |server|
    server.vm.hostname = "central-server"
    server.vm.network "private_network",
                      ip: "192.168.100.2",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus21-servers"
    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-21-central-server"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "inetRouter2" do |router|
    router.vm.hostname = "inet-router2"
    router.vm.network "private_network", ip: "192.168.56.21"
    router.vm.network "private_network",
                      ip: "192.168.100.3",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus21-servers"
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-21-inet-router2"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    router.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "routers" => ["inetRouter", "centralRouter", "inetRouter2"],
        "internal_nodes" => ["centralRouter", "centralServer", "inetRouter2"]
      }
    end
  end
end
