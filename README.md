## Задание 18. Reserve copy

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/18-reserve-copy

### Задание

Нужно поднять стенд Vagrant с двумя машинами: `backup_server` и `client`.

С `client` нужно делать удаленный backup каталога `/etc` через `borgbackup`.

Что должно быть настроено:

- каталог `/var/backup` на `backup_server`;
- `/var/backup` должен быть отдельной точкой монтирования, для стенда достаточно диска 2GB;
- borg-репозиторий должен быть зашифрован;
- имя архива должно содержать время создания;
- хранение: ежедневные копии за последние три месяца и месячные копии за год;
- backup должен запускаться каждые 5 минут;
- backup должен запускаться скриптом через cron или systemd timer;
- процесс backup должен логироваться;
- нужно показать логи backup и восстановление `/etc` из резервной копии.

### Файлы

`Vagrantfile` поднимает две машины: `backup_server` и `client`.

`ansible/playbook.yml` настраивает borgbackup, диск `/var/backup`, доступ по ssh, systemd service и timer.

`ansible/templates/borg-backup.sh.j2` содержит скрипт резервного копирования.

`ansible/files/borg-backup.service` и `ansible/files/borg-backup.timer` описывают запуск backup через systemd.

`ansible.cfg` отключает проверку host key для Ansible и задает обычные параметры запуска.

### Запуск

```bash
vagrant up
```

После запуска Ansible должен завершиться без ошибок:

```text
PLAY RECAP *********************************************************************
backup_server              : ok=11   changed=1    unreachable=0    failed=0    skipped=1
client                     : ok=13   changed=8    unreachable=0    failed=0    skipped=1
```

### Что настроено

На `backup_server` установлен `borgbackup`, создан пользователь `borg`, отдельный диск 2GB смонтирован в `/var/backup`.

На `client` установлен `borgbackup`, создан ssh-ключ для доступа к `backup_server`, настроен зашифрованный borg-репозиторий:

```text
borg@192.168.56.18:/var/backup/etc.borg
```

Backup запускается через `borg-backup.timer`. Сам backup выполняет скрипт `/usr/local/sbin/borg-backup.sh`.

В скрипте задана политика хранения:

```bash
borg prune --keep-daily=90 --keep-monthly=12
```

Так остаются ежедневные копии за последние три месяца и месячные копии за год.

### Проверка диска для backup

Команда:

```bash
vagrant ssh backup_server -c "df -h /var/backup"
```

Вывод:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb        2.0G  4.8M  1.8G   1% /var/backup
```

Команда:

```bash
vagrant ssh backup_server -c "findmnt /var/backup"
```

Вывод:

```text
TARGET      SOURCE   FSTYPE OPTIONS
/var/backup /dev/sdb ext4   rw,relatime
```

### Проверка таймера

Команда:

```bash
vagrant ssh client -c "sudo systemctl list-timers --all borg-backup.timer --no-pager"
```

Вывод:

```text
NEXT                        LEFT          LAST                        PASSED       UNIT              ACTIVATES
Tue 2026-07-07 08:56:11 UTC 4min 38s left Tue 2026-07-07 08:48:07 UTC 3min 24s ago borg-backup.timer borg-backup.service

1 timers listed.
```

### Проверка архивов

Стенд был запущен больше 30 минут. В репозитории видны архивы с временем создания в имени.

Команда:

```bash
vagrant ssh client -c "sudo env BORG_PASSPHRASE=otus-borg-passphrase BORG_RSH='ssh -i /root/.ssh/borg_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/known_hosts -o BatchMode=yes' borg list borg@192.168.56.18:/var/backup/etc.borg"
```

Вывод:

```text
etc-2026-07-06_22-32-27              Mon, 2026-07-06 22:32:28 [53ea2c7f01fe5ed4b963556bf04d024b9f6a84cc1d0a3e624dcae75bd35ac766]
etc-2026-07-06_23-55-53              Mon, 2026-07-06 23:55:53 [e55e05ec04b49e8512c660a0949c6e3bc4acb4a4f85581f2135f7f4ec6234eda]
etc-2026-07-07_08-48-07              Tue, 2026-07-07 08:48:08 [5c8d3e7bb3dca59f4299b56474b8b850d2b146c61f894188c528ba6527f984de]
```

### Логи backup

Логи пишутся через `logger` с тегом `borg-backup`.

Команда:

```bash
vagrant ssh client -c "sudo journalctl -t borg-backup --no-pager -n 50"
```

Фрагмент вывода:

```text
Jul 07 08:48:07 client borg-backup[4210]: Starting backup etc-2026-07-07_08-48-07
Jul 07 08:48:08 client borg-backup[4210]: Repository: ssh://borg@192.168.56.18/var/backup/etc.borg
Jul 07 08:48:08 client borg-backup[4210]: Archive name: etc-2026-07-07_08-48-07
Jul 07 08:48:08 client borg-backup[4210]: Time (start): Tue, 2026-07-07 08:48:08
Jul 07 08:48:08 client borg-backup[4210]: Time (end):   Tue, 2026-07-07 08:48:08
Jul 07 08:48:08 client borg-backup[4210]: Number of files: 794
Jul 07 08:48:08 client borg-backup[4210]: Keeping archive (rule: daily #1):        etc-2026-07-07_08-48-07
Jul 07 08:48:08 client borg-backup[4210]: Pruning archive (1/1):                   etc-2026-07-07_08-47-08
Jul 07 08:48:08 client borg-backup[4210]: Keeping archive (rule: daily #2):        etc-2026-07-06_23-55-53
Jul 07 08:48:08 client borg-backup[4210]: Keeping archive (rule: daily[oldest] #3): etc-2026-07-06_22-32-27
Jul 07 08:48:08 client borg-backup[4210]: Finished backup etc-2026-07-07_08-48-07
```

### Восстановление `/etc`

Перед восстановлением backup был остановлен:

```bash
vagrant ssh client -c "sudo systemctl disable --now borg-backup.timer"
```

Последний архив был извлечен во временный каталог, после этого текущий `/etc` был перемещен в `/etc.before-restore`, а восстановленный каталог поставлен на место.

Команды внутри `client`:

```bash
sudo bash
export BORG_REPO="borg@192.168.56.18:/var/backup/etc.borg"
export BORG_PASSPHRASE="otus-borg-passphrase"
export BORG_RSH="ssh -i /root/.ssh/borg_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/known_hosts -o BatchMode=yes"
latest="$(borg list --last 1 --short "$BORG_REPO")"
rm -rf /tmp/restore-root
mkdir -p /tmp/restore-root
cd /tmp/restore-root
borg extract "$BORG_REPO::${latest}" etc
mv /etc /etc.before-restore
mv /tmp/restore-root/etc /etc
test -f /etc/hostname
test -f /etc/passwd
test -d /etc/ssh
test -d /etc/systemd
```

Вывод проверки:

```text
archive: etc-2026-07-07_08-48-07
restore ok
drwxr-xr-x 95 root root 4096 Jul  7 08:39 /etc
drwxr-xr-x 95 root root 4096 Jul  7 08:39 /etc.before-restore
-rw-r--r-- 1 root root    7 Jul  7 08:39 /etc/hostname
-rw-r--r-- 1 root root 1814 Oct 23  2025 /etc/passwd
-rw-r--r-- 1 root root 3288 Oct 23  2025 /etc/ssh/sshd_config
```

После восстановления SSH-доступ к машине работает:

```text
client
ssh-after-restore-ok
```

Timer был включен обратно:

```bash
vagrant ssh client -c "sudo systemctl enable --now borg-backup.timer"
```
