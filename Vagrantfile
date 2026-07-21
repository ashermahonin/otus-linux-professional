# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/almalinux-9"
  config.vm.box_version = "202510.26.0"

  config.vm.define "ipaServer" do |server|
    server.vm.hostname = "ipa.otus.test"
    server.vm.network "private_network",
                      ip: "192.168.56.10",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus26-ldap"
    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-26-ipaServer"
      virtualbox.memory = 3072
      virtualbox.cpus = 2
    end
  end

  config.vm.define "ipaClient" do |client|
    client.vm.hostname = "client.otus.test"
    client.vm.network "private_network",
                      ip: "192.168.56.20",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus26-ldap"
    client.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-26-ipaClient"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    client.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "ipa_server" => ["ipaServer"],
        "ipa_clients" => ["ipaClient"]
      }
    end
  end
end
