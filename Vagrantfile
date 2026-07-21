# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  config.vm.define "ns01" do |server|
    server.vm.hostname = "ns01"
    server.vm.network "private_network",
                      ip: "192.168.50.10",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus24-dns"
    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-24-ns01"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "ns02" do |server|
    server.vm.hostname = "ns02"
    server.vm.network "private_network",
                      ip: "192.168.50.11",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus24-dns"
    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-24-ns02"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "client1" do |client|
    client.vm.hostname = "client1"
    client.vm.network "private_network",
                      ip: "192.168.50.15",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus24-dns"
    client.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-24-client1"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "client2" do |client|
    client.vm.hostname = "client2"
    client.vm.network "private_network",
                      ip: "192.168.50.16",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus24-dns"
    client.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-24-client2"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    client.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "dns_servers" => ["ns01", "ns02"],
        "clients" => ["client1", "client2"]
      }
    end
  end
end
