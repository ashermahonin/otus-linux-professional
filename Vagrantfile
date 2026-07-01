# frozen_string_literal: true

NFS_BOX = ENV.fetch("OTUS_NFS_BOX", "bento/ubuntu-22.04")
NFS_SERVER_IP = "192.168.56.10"
NFS_CLIENT_IP = "192.168.56.11"

Vagrant.configure("2") do |config|
  config.vm.box = NFS_BOX
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  # The homework is about guest-to-guest NFS, so the default /vagrant share is disabled.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 1
    vb.memory = 1024
  end

  config.vm.define "nfs_server", primary: true do |server|
    server.vm.hostname = "nfs-server"
    server.vm.network "private_network", ip: NFS_SERVER_IP
    server.vm.provision "shell", path: "scripts/provision-nfs-server.sh"

    server.vm.provider "virtualbox" do |vb|
      vb.name = "otus-5-nfs-server"
    end
  end

  config.vm.define "nfs_client" do |client|
    client.vm.hostname = "nfs-client"
    client.vm.network "private_network", ip: NFS_CLIENT_IP
    client.vm.provision "shell",
                        path: "scripts/provision-nfs-client.sh",
                        env: {
                          "NFS_SERVER_IP" => NFS_SERVER_IP
                        }

    client.vm.provider "virtualbox" do |vb|
      vb.name = "otus-5-nfs-client"
    end
  end
end

