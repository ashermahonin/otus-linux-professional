# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "vpn-server" do |server|
    server.vm.hostname = "vpn-server"
    server.vm.network "private_network",
                      ip: "192.168.56.10",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus23-vpn"
    server.vm.network "forwarded_port",
                      guest: 1194,
                      host: 1194,
                      protocol: "udp",
                      host_ip: "127.0.0.1"
    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-23-vpn-server"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

  end

  config.vm.define "vpn-client" do |client|
    client.vm.hostname = "vpn-client"
    client.vm.network "private_network",
                      ip: "192.168.56.20",
                      netmask: "255.255.255.0",
                      virtualbox__intnet: "otus23-vpn"
    client.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-23-vpn-client"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    client.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "vpn_server" => ["vpn-server"],
        "vpn_client" => ["vpn-client"]
      }
    end
  end

end
