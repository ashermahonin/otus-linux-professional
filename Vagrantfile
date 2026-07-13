# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "router1" do |router|
    router.vm.hostname = "router1"
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link12",
                      auto_config: false
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link13",
                      auto_config: false
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-22-router1"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "router2" do |router|
    router.vm.hostname = "router2"
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link12",
                      auto_config: false
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link23",
                      auto_config: false
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-22-router2"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end
  end

  config.vm.define "router3" do |router|
    router.vm.hostname = "router3"
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link13",
                      auto_config: false
    router.vm.network "private_network",
                      virtualbox__intnet: "otus22-link23",
                      auto_config: false
    router.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-22-router3"
      virtualbox.memory = 1024
      virtualbox.cpus = 1
    end

    router.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "routers" => ["router1", "router2", "router3"]
      }
    end
  end
end
