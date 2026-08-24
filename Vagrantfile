MACHINES = {
  "edge1" => {
    memory: 1024,
    networks: { external: "192.168.56.11", dmz: "10.10.10.11" }
  },
  "edge2" => {
    memory: 1024,
    networks: { external: "192.168.56.12", dmz: "10.10.10.12" }
  },
  "app1" => {
    memory: 1024,
    networks: { dmz: "10.10.10.21", backend: "10.10.20.21" }
  },
  "app2" => {
    memory: 1024,
    networks: { dmz: "10.10.10.22", backend: "10.10.20.22" }
  },
  "db1" => {
    memory: 1024,
    networks: { backend: "10.10.20.31" }
  },
  "db2" => {
    memory: 1024,
    networks: { backend: "10.10.20.32" }
  },
  "db3" => {
    memory: 1024,
    networks: { backend: "10.10.20.33" }
  },
  "log" => {
    memory: 1024,
    networks: { dmz: "10.10.10.250", backend: "10.10.20.250" }
  },
  "backup" => {
    memory: 1024,
    networks: { backend: "10.10.20.40" }
  },
  "monitor" => {
    memory: 1536,
    networks: { external: "192.168.56.50", dmz: "10.10.10.50", backend: "10.10.20.50" }
  }
}.freeze

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  MACHINES.each do |name, machine|
    config.vm.define name do |server|
      server.vm.hostname = name

      machine[:networks].each do |network, ip|
        if network == :external
          server.vm.network "private_network", ip: ip, netmask: "255.255.255.0"
        else
          server.vm.network "private_network",
                            ip: ip,
                            netmask: "255.255.255.0",
                            virtualbox__intnet: "otus-final-#{network}"
        end
      end

      server.vm.provider "virtualbox" do |virtualbox|
        virtualbox.name = "otus-final-#{name}"
        virtualbox.memory = machine[:memory]
        virtualbox.cpus = 1
      end

      next unless name == "monitor"

      server.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/playbook.yml"
        ansible.limit = "all"
        ansible.groups = {
          "edge" => %w[edge1 edge2],
          "application" => %w[app1 app2],
          "database" => %w[db1 db2 db3],
          "log_server" => ["log"],
          "backup_server" => ["backup"],
          "monitoring" => ["monitor"]
        }
      end
    end
  end
end
