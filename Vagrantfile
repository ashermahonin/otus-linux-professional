# -*- mode: ruby -*-

MACHINES = {
  postgresPrimary: {
    hostname: "postgres-primary",
    ip: "192.168.56.101",
    memory: 1024,
    cpus: 1
  },
  postgresStandby: {
    hostname: "postgres-standby",
    ip: "192.168.56.102",
    memory: 1024,
    cpus: 1
  },
  barman: {
    hostname: "barman",
    ip: "192.168.56.103",
    memory: 1024,
    cpus: 1
  }
}.freeze

Vagrant.configure("2") do |config|
  config.vm.box = "local/ubuntu-24.04"

  MACHINES.each do |name, machine|
    config.vm.define name do |server|
      server.vm.hostname = machine[:hostname]
      server.vm.network "private_network",
                        ip: machine[:ip],
                        netmask: "255.255.255.0",
                        virtualbox__intnet: "otus29-postgres"

      server.vm.provider "virtualbox" do |virtualbox|
        virtualbox.name = "otus-29-#{machine[:hostname]}"
        virtualbox.memory = machine[:memory]
        virtualbox.cpus = machine[:cpus]
      end

      # Ansible запускается после старта всех трёх машин.
      next unless name == :barman

      server.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/playbook.yml"
        ansible.limit = "all"
        ansible.groups = {
          "postgres_primary" => ["postgresPrimary"],
          "postgres_standby" => ["postgresStandby"],
          "barman_servers" => ["barman"]
        }
      end
    end
  end
end
