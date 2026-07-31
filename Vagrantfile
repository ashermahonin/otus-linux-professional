MACHINES = {
  "master" => {
    ip: "192.168.56.101",
    config: "master.cnf"
  },
  "slave" => {
    ip: "192.168.56.102",
    config: "slave.cnf"
  }
}.freeze

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  MACHINES.each do |name, machine|
    config.vm.define name do |server|
      server.vm.hostname = "mysql-#{name}"
      server.vm.network "private_network", ip: machine[:ip]

      server.vm.provider "virtualbox" do |virtualbox|
        virtualbox.name = "otus-28-mysql-#{name}"
        virtualbox.memory = 1024
        virtualbox.cpus = 2
      end

      server.vm.provision "shell", inline: <<~SHELL
        set -euo pipefail
        export DEBIAN_FRONTEND=noninteractive

        apt-get update
        apt-get install -y mysql-server

        install -d -m 0755 /etc/mysql/mysql.conf.d
        install -m 0644 /vagrant/configs/#{machine[:config]} /etc/mysql/mysql.conf.d/z-otus.cnf
        systemctl enable mysql
        systemctl restart mysql

        until mysqladmin --protocol=socket ping >/dev/null 2>&1; do
          sleep 2
        done

        if [ "#{name}" = "master" ]; then
          mysql -uroot <<'SQL'
        CREATE DATABASE IF NOT EXISTS bet;
        CREATE USER IF NOT EXISTS 'repl'@'192.168.56.%' IDENTIFIED BY 'OtusMySQL-repl-2026';
        GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'192.168.56.%';
        CREATE USER IF NOT EXISTS 'dump'@'192.168.56.%' IDENTIFIED BY 'OtusMySQL-dump-2026';
        GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES ON bet.* TO 'dump'@'192.168.56.%';
        FLUSH PRIVILEGES;
        SQL

          if ! mysql -uroot -NBe "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'bet'" | grep -q '^7$'; then
            mysql -uroot bet < /vagrant/bet.dmp
          fi

          echo "Master tables:"
          mysql -uroot -e "SHOW TABLES FROM bet"
          echo "GTID mode:"
          mysql -uroot -e "SHOW VARIABLES LIKE 'gtid_mode'"
        else
          for attempt in $(seq 1 30); do
            if mysqladmin -h 192.168.56.101 -udump -pOtusMySQL-dump-2026 ping >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done
          mysqladmin -h 192.168.56.101 -udump -pOtusMySQL-dump-2026 ping >/dev/null

          mysql -uroot -e "STOP REPLICA" 2>/dev/null || true
          mysql -uroot -e "RESET REPLICA ALL" 2>/dev/null || true
          mysql -uroot -e "SET GLOBAL super_read_only = OFF; SET GLOBAL read_only = OFF"
          mysql -uroot -e "DROP DATABASE IF EXISTS bet; CREATE DATABASE bet"

          mysqldump --single-transaction --skip-lock-tables --no-tablespaces \
            --set-gtid-purged=OFF --ignore-table=bet.events_on_demand \
            --ignore-table=bet.v_same_event \
            -h 192.168.56.101 -udump -pOtusMySQL-dump-2026 bet \
            | mysql --init-command="SET SESSION sql_log_bin=0" -uroot bet

          source_gtid="$(mysql -h 192.168.56.101 -urepl -pOtusMySQL-repl-2026 -NBe "SELECT @@GLOBAL.gtid_executed")"
          mysql -uroot -e "RESET MASTER"
          mysql -uroot -e "SET GLOBAL gtid_purged = '${source_gtid}'"
          mysql -uroot -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.56.101', SOURCE_PORT=3306, SOURCE_USER='repl', SOURCE_PASSWORD='OtusMySQL-repl-2026', SOURCE_AUTO_POSITION=1"
          mysql -uroot -e "START REPLICA"
          mysql -uroot -e "SET GLOBAL read_only = ON; SET GLOBAL super_read_only = ON"

          for attempt in $(seq 1 30); do
            replica_status="$(mysql -uroot -e "SHOW REPLICA STATUS\\G")"
            if printf '%s\\n' "$replica_status" | grep -q "Replica_IO_Running: Yes" \
              && printf '%s\\n' "$replica_status" | grep -q "Replica_SQL_Running: Yes"; then
              break
            fi
            sleep 2
          done

          printf '%s\\n' "$replica_status"
          printf '%s\\n' "$replica_status" | grep -q "Replica_IO_Running: Yes"
          printf '%s\\n' "$replica_status" | grep -q "Replica_SQL_Running: Yes"
          echo "Slave tables:"
          mysql -uroot -e "SHOW TABLES FROM bet"
        fi
      SHELL
    end
  end
end
