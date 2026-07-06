Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "pam-weekend"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "otus-16-pam"
    vb.memory = 1024
    vb.cpus = 1
  end

  config.vm.provision "shell", inline: <<-'SHELL'
    set -e

    if ! getent group admin >/dev/null; then
      groupadd admin
    fi

    if ! id otus >/dev/null 2>&1; then
      useradd -m -s /bin/bash otus
    fi

    if ! id otusadm >/dev/null 2>&1; then
      useradd -m -s /bin/bash -G admin,sudo otusadm
    fi

    usermod -aG admin,sudo vagrant
    echo "otus:otus" | chpasswd
    echo "otusadm:otus" | chpasswd

    mkdir -p /etc/security
    cat >/etc/security/pam_holidays <<'EOF'
04-07-2026
EOF

    cat >/usr/local/bin/pam_weekend_check.sh <<'EOF'
#!/bin/bash
set -euo pipefail

user="${PAM_USER:-}"

if [ -z "$user" ]; then
  exit 1
fi

if id -nG "$user" | tr ' ' '\n' | grep -qx admin; then
  exit 0
fi

today="${PAM_TEST_DATE:-$(date +%d-%m-%Y)}"
weekday="${PAM_TEST_WEEKDAY:-$(date +%u)}"

if grep -qx "$today" /etc/security/pam_holidays; then
  exit 0
fi

case "$weekday" in
  6|7)
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
EOF

    chown root:root /usr/local/bin/pam_weekend_check.sh /etc/security/pam_holidays
    chmod 0755 /usr/local/bin/pam_weekend_check.sh
    chmod 0644 /etc/security/pam_holidays

    if ! grep -q "pam_weekend_check.sh" /etc/pam.d/sshd; then
      sed -i '/@include common-account/i account required pam_exec.so quiet /usr/local/bin/pam_weekend_check.sh' /etc/pam.d/sshd
    fi

    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh
  SHELL
end
