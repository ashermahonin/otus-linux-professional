## Материал для защиты

### Идея проекта

Тема проекта: отказоустойчивое развертывание защищенного веб-сервиса. WordPress используется как прикладная часть, а инфраструктура вокруг него показывает работу с DMZ, reverse proxy, firewall, репликацией базы, мониторингом, логированием и backup.

Внешний адрес стенда — `192.168.56.10`. Это виртуальный IP Keepalived, который может находиться на `edge1` или `edge2`. Оба edge-узла используют одинаковую конфигурацию Nginx и TLS.

### Роли виртуальных машин

| Узел | Назначение | Сеть |
| --- | --- | --- |
| edge1, edge2 | DMZ, HTTPS, входной firewall, балансировка | внешняя сеть и DMZ |
| app1, app2 | WordPress, PHP-FPM, локальный HAProxy к БД | DMZ и backend |
| db1, db2, db3 | MariaDB Galera | backend |
| log | централизованный rsyslog | DMZ и backend |
| backup | зашифрованные Borg-репозитории | backend |
| monitor | Prometheus, Grafana, Alertmanager, Blackbox | внешняя сеть, DMZ и backend |

### Порядок развёртывания

1. Vagrant создаёт и запускает все десять ВМ.
2. Ansible устанавливает базовые пакеты, rsyslog и node exporter.
3. Узел `log` начинает принимать TCP/UDP syslog, после чего остальные ВМ включают удалённую отправку с дисковой очередью.
4. Ansible по очереди поднимает `db1`, `db2`, `db3`. Первый сервер запускает начальный компонент Galera, остальные присоединяются. После этого проверяется размер кластера `3`.
5. Создаётся пользователь Borg на backup-сервере, затем application-узлы получают ключи, WordPress и локальный HAProxy.
6. Для каждого application-узла создаётся отдельный зашифрованный Borg-репозиторий и включается systemd timer.
7. На edge-узлах включаются Nginx, Keepalived и сервис с правилами iptables.
8. На `monitor` поднимается Docker Compose со стеком мониторинга.

### Безопасность

На edge-узлах политика `INPUT` и `FORWARD` — `DROP`. Разрешены:

- TCP 443 для HTTPS;
- SSH только из служебных сетей Vagrant и хоста;
- протокол VRRP между edge1 и edge2;
- TCP 9100 от monitor для node exporter.

Приложения не доступны напрямую из внешней сети. Nginx на edge принимает TLS 1.2 и TLS 1.3, затем передаёт запросы в DMZ. Для лабораторного стенда сертификат самоподписанный, поэтому при проверке `curl` используется ключ `-k`.

### Мониторинг и алерты

Prometheus собирает метрики node exporter со всех десяти ВМ. Blackbox exporter проверяет HTTPS на виртуальном IP. Правила:

- `InstanceDown` — node exporter не отвечает одну минуту;
- `WebEndpointDown` — HTTPS не отвечает 30 секунд.

Alertmanager готов к Telegram. Пока файл с секретами не создан, сообщения не отправляются. После добавления токена и идентификатора чата Ansible генерирует Telegram receiver. Секреты не попадают в Git благодаря `.gitignore`.

### Логи

Rsyslog на `log` принимает TCP и UDP 514 и записывает сообщения в `/var/log/remote/<hostname>/syslog`. На клиентах используется очередь с дисковым файлом `remote-queue`, поэтому при недоступности `log` сообщения сохраняются локально и передаются после восстановления соединения. Nginx access/error логи читаются rsyslog через `imfile` и уходят тем же каналом.

### Backup и восстановление

На каждом application-узле каждые 15 минут запускается `wordpress-backup.service`. Перед созданием архива выполняется `mariadb-dump` через локальный HAProxy. В Borg попадают:

- `/var/www/wordpress`;
- дамп базы в `/var/backups/wordpress/database.sql`;
- `/etc/nginx`.

Репозитории созданы с `repokey-blake2`. Политика хранения: все копии за семь дней, дневные за неделю, недельные за месяц и месячные за полгода.

Для восстановления файлов на application-узле:

```bash
sudo -i
export BORG_REPO='borg@10.10.20.40:/var/backup/borg/app1'
export BORG_PASSPHRASE='OtusBorg-2026'
export BORG_RSH='ssh -i /root/.ssh/borg_ed25519'
borg list
borg extract ::имя_архива var/www/wordpress
```

Дамп базы восстанавливается командой:

```bash
mariadb -h 127.0.0.1 -u wordpress -p wordpress < /var/backups/wordpress/database.sql
```

### Поведение при отказах

| Отключённый узел | Что происходит |
| --- | --- |
| edge1 или edge2 | Второй edge-узел забирает виртуальный IP примерно за 1-3 секунды. HTTPS остаётся доступным. |
| app1 или app2 | Nginx на edge помечает недоступный upstream и направляет запросы на оставшийся application-узел. |
| db1, db2 или db3 | Два оставшихся узла Galera сохраняют кворум. Локальный HAProxy на application-узлах исключает недоступный сервер из backend. |
| log | Веб-сайт и БД продолжают работать. rsyslog хранит очередь локально и передаёт её после возврата log. |
| backup | Веб-сайт продолжает работать. Очередной запуск timer повторит backup после восстановления backup-сервера. |
| monitor | Работа сайта не зависит от monitor. На время его остановки новые алерты не формируются; после запуска Docker restart policy поднимает сервисы мониторинга. |

Остановка целой ВМ средствами VirtualBox не может быть отменена самой ВМ. В стенде для критичных частей используется резервирование: edge, app и DB продолжают работу при отказе одного участника. После возврата выключенной ВМ systemd запускает её сервисы автоматически, а Galera присоединяет DB-узел обратно к кластеру.

### Команды для демонстрации

Проверка текущего владельца VIP:

```bash
vagrant ssh edge1 -c 'ip -4 addr show | grep 192.168.56.10'
vagrant ssh edge2 -c 'ip -4 addr show | grep 192.168.56.10'
```

Проверка кворума Galera:

```bash
vagrant ssh db1 -c "sudo mariadb -NBe \"SHOW STATUS LIKE 'wsrep_cluster_size'\""
```

Проверка отправки логов:

```bash
vagrant ssh app1 -c 'logger -t final-project test-log-message'
vagrant ssh log -c 'sudo grep test-log-message /var/log/remote/app1/syslog'
```

Проверка backup:

```bash
vagrant ssh app1 -c 'sudo systemctl start wordpress-backup.service'
vagrant ssh backup -c 'sudo -u borg borg list /var/backup/borg/app1'
```

Проверка переключения edge:

```bash
vagrant halt edge1
curl -k --resolve web.local:443:192.168.56.10 https://web.local/
vagrant up edge1
```
