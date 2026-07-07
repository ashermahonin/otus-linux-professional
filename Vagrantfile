# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "backup_server" do |backup|
    backup.vm.hostname = "backup-server"
    backup.vm.network "private_network", ip: "192.168.56.18"

    backup.vm.provider "virtualbox" do |v|
      v.name = "otus-18-backup-server"
      v.memory = 1024
      v.cpus = 1

      disk_path = File.join(__dir__, "backup.vdi")

      unless File.exist?(disk_path)
        v.customize ["createmedium", "disk", "--filename", disk_path, "--size", 2048, "--format", "VDI"]
      end

      v.customize ["storageattach", :id, "--storagectl", "VirtIO Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", disk_path]
    end
  end

  config.vm.define "client" do |client|
    client.vm.hostname = "client"
    client.vm.network "private_network", ip: "192.168.56.19"

    client.vm.provider "virtualbox" do |v|
      v.name = "otus-18-client"
      v.memory = 1024
      v.cpus = 1
    end

    client.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
        "backup_servers" => ["backup_server"],
        "clients" => ["client"]
      }
      ansible.extra_vars = {
        backup_server_ip: "192.168.56.18",
        borg_repo: "borg@192.168.56.18:/var/backup/etc.borg",
        borg_passphrase: "otus-borg-passphrase"
      }
    end
  end
end
