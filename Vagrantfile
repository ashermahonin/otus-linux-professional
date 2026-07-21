# -*- mode: ruby -*-

MACHINES = {
  "inetRouter" => {
    adapters: [
      { slot: 2, network: "otus25-inet-link1", promisc: true },
      { slot: 3, network: "otus25-inet-link2", promisc: true }
    ]
  },
  "centralRouter" => {
    adapters: [
      { slot: 2, network: "otus25-central-link1", promisc: true },
      { slot: 3, network: "otus25-central-link2", promisc: true }
    ]
  },
  "testClient1" => {
    adapters: [{ slot: 2, network: "otus25-testLAN" }]
  },
  "testClient2" => {
    adapters: [{ slot: 2, network: "otus25-testLAN" }]
  },
  "testServer1" => {
    adapters: [{ slot: 2, network: "otus25-testLAN" }]
  },
  "testServer2" => {
    adapters: [{ slot: 2, network: "otus25-testLAN" }]
  },
  "lacpSwitch" => {
    adapters: [
      { slot: 2, network: "otus25-central-link1", promisc: true },
      { slot: 3, network: "otus25-central-link2", promisc: true },
      { slot: 4, network: "otus25-inet-link1", promisc: true },
      { slot: 5, network: "otus25-inet-link2", promisc: true }
    ]
  }
}.freeze

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  MACHINES.each do |name, machine|
    config.vm.define name do |node|
      node.vm.hostname = name

      node.vm.provider "virtualbox" do |virtualbox|
        virtualbox.name = "otus-25-#{name}"
        virtualbox.memory = 1024
        virtualbox.cpus = 1

        machine[:adapters].each do |adapter|
          virtualbox.customize [
            "modifyvm", :id, "--nic#{adapter[:slot]}", "intnet"
          ]
          virtualbox.customize [
            "modifyvm", :id, "--intnet#{adapter[:slot]}", adapter[:network]
          ]
          next unless adapter[:promisc]

          virtualbox.customize [
            "modifyvm", :id, "--nicpromisc#{adapter[:slot]}", "allow-all"
          ]
        end
      end

      next unless name == "lacpSwitch"

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/playbook.yml"
        ansible.limit = "all"
        ansible.groups = {
          "bond_routers" => ["inetRouter", "centralRouter"],
          "vlan10" => ["testClient1", "testServer1"],
          "vlan20" => ["testClient2", "testServer2"],
          "lacp_switch" => ["lacpSwitch"]
        }
      end
    end
  end
end
