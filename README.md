## Задание 28. PostgreSQL

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/28-postgres

### Текст задания

Нужно настроить hot_standby репликацию PostgreSQL с использованием слотов и резервное копирование.

### Файлы

`Vagrantfile` поднимает три виртуальные машины: `postgresPrimary`, `postgresStandby` и `barman`.

`ansible/playbook.yml` устанавливает PostgreSQL 16 и Barman, настраивает репликацию, создаёт резервную копию и выполняет проверки.

В `ansible/templates` находятся конфигурации PostgreSQL, доступа к базе, реплики и Barman.

### Реализация

На `postgresPrimary` работает основная база. Для `postgresStandby` создан физический слот `standby_slot`. Реплика клонируется через `pg_basebackup` и получает изменения от основной базы в режиме hot standby.

На `barman` установлен Barman. Он делает потоковую резервную копию основной базы, получает WAL через слот `barman_slot`, сжимает копии gzip и хранит их по политике `RECOVERY WINDOW OF 7 DAYS`. Обслуживание Barman запускается каждые пять минут, резервная копия создаётся каждый день в 02:00.

В PostgreSQL 16 режим реплики включается файлом `standby.signal`. Параметры подключения к основной базе находятся в `recovery.conf`, который подключается из `otus.conf`.

### Команды и вывод

Запуск стенда:

~~~bash
vagrant up
~~~

Проверка состояния репликации:

~~~bash
vagrant ssh postgresPrimary -c "sudo -u postgres psql -c \"SELECT slot_name, active FROM pg_replication_slots;\""
vagrant ssh postgresStandby -c "sudo -u postgres psql -tAc 'SELECT pg_is_in_recovery();'"
~~~

Полученный результат:

~~~text
 standby_slot:true
 t
~~~

Проверка данных на реплике:

~~~bash
vagrant ssh postgresStandby -c "sudo -u postgres psql -d otus -c 'SELECT * FROM replication_check;'"
~~~

~~~text
replication is working
~~~

Проверка резервной копии:

~~~bash
vagrant ssh barman -c "sudo -u barman barman check primary"
vagrant ssh barman -c "sudo -u barman barman list-backup primary"
~~~

После запуска получены результаты:

~~~text
 PostgreSQL: OK
 PostgreSQL streaming: OK
 replication slot: OK
 receive-wal running: OK
 minimum redundancy requirements: OK (have 2 backups, expected at least 1)
 primary 20260730T133947 - Thu Jul 30 13:39:47 2026 - Size: 22.3 MiB
~~~

### Заметки

- Пароли в плейбуке учебные и используются только внутри изолированной сети стенда.
- Созданная при развертывании резервная копия нужна для проверки Barman. Следующие копии запускаются по расписанию.
