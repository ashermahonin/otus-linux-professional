# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  config.vm.define "dynamicWeb" do |server|
    server.vm.hostname = "dynamic-web"
    server.vm.network "forwarded_port", guest: 8081, host: 8081
    server.vm.network "forwarded_port", guest: 8082, host: 8082
    server.vm.network "forwarded_port", guest: 8083, host: 8083

    server.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "otus-27-dynamicWeb"
      virtualbox.memory = 3072
      virtualbox.cpus = 2
    end

    server.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "dynamic_web" => ["dynamicWeb"]
      }
    end
  end
end
