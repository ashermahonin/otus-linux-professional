# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "vagrant-disks"

  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1

    {
      "disk1.vdi" => 1,
      "disk2.vdi" => 2
    }.each do |disk_name, port|
      disk_path = File.join(__dir__, disk_name)

      unless File.exist?(disk_path)
        v.customize ["createmedium", "disk", "--filename", disk_path, "--size", 1024, "--format", "VDI"]
      end

      v.customize ["storageattach", :id, "--storagectl", "VirtIO Controller", "--port", port, "--device", 0, "--type", "hdd", "--medium", disk_path]
    end
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    for item in "/dev/sdb:/mnt/disk1" "/dev/sdc:/mnt/disk2"; do
      disk="${item%%:*}"
      mount_point="${item##*:}"

      for attempt in $(seq 1 30); do
        [ -b "$disk" ] && break
        sleep 1
      done

      if [ ! -b "$disk" ]; then
        echo "Disk $disk not found"
        exit 1
      fi

      current_fs=$(blkid -s TYPE -o value "$disk" 2>/dev/null || true)
      if [ "$current_fs" != "ext4" ]; then
        mkfs.ext4 -F "$disk"
      fi

      mkdir -p "$mount_point"

      uuid=$(blkid -s UUID -o value "$disk")
      sed -i "\\| $mount_point ext4 |d" /etc/fstab
      echo "UUID=$uuid $mount_point ext4 defaults,nofail 0 2" >> /etc/fstab
    done

    mount -a
  SHELL
end
