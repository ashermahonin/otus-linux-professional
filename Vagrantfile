# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "pxe_server" do |server|
    server.vm.hostname = "pxe-server"
    server.vm.network "private_network",
                      ip: "192.168.56.20",
                      virtualbox__intnet: "pxe-net"

    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-20-pxe-server"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    server.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
    end
  end

  config.vm.define "pxe_client" do |client|
    client.vm.hostname = "pxe-client"
    client.vm.communicator = "none"
    client.vm.network "private_network",
                      type: "dhcp",
                      auto_config: false,
                      virtualbox__intnet: "pxe-net"

    client.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-20-pxe-client"
      virtualbox.memory = 2048
      virtualbox.cpus = 1
      virtualbox.customize ["modifyvm", :id, "--boot1", "net"]
      virtualbox.customize ["modifyvm", :id, "--boot2", "disk"]
      virtualbox.customize ["modifyvm", :id, "--nic1", "none"]
      virtualbox.customize ["modifyvm", :id, "--nic-boot-prio1", "0"]
      virtualbox.customize ["modifyvm", :id, "--nic-boot-prio2", "1"]
    end
  end
end
