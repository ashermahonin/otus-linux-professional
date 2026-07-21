## Задание 26. LDAP

### Текст задания

Нужно установить FreeIPA и написать Ansible-playbook для настройки LDAP-клиента.

### Файлы

`Vagrantfile` поднимает две виртуальные машины в изолированной сети `192.168.56.0/24`.

`ansible/playbook.yml` устанавливает FreeIPA на сервер, настраивает DNS-зону `otus.test`, подключает клиента и проверяет получение пользователя через SSSD.

### Реализация

Сервер `ipa.otus.test` имеет адрес `192.168.56.10`. На нём установлен FreeIPA с собственным DNS. В firewall открыты LDAP и DNS.

Клиент `client.otus.test` имеет адрес `192.168.56.20`. Ansible устанавливает `ipa-client`, указывает FreeIPA как DNS-сервер и запускает `ipa-client-install`. Параметр `--mkhomedir` создаёт домашний каталог при первом входе пользователя.

Для проверки на сервере создаётся пользователь `otususer`. На клиенте команда `getent passwd otususer` получает его запись из FreeIPA.

### Команды и вывод

Запуск стенда:

~~~bash
vagrant up
~~~

Проверка клиента:

~~~bash
vagrant ssh ipaClient -c 'getent passwd otususer'
vagrant ssh ipaClient -c 'id otususer'
~~~

После запуска получены результаты:

~~~text
otususer:*:739600003:739600003:Otus User:/home/otususer:/bin/sh
uid=739600003(otususer) gid=739600003(otususer) groups=739600003(otususer)
sssd: active
realm: configured: kerberos-member
~~~

### Заметки

- FreeIPA требует постоянное полное имя хоста и его разрешение в IP-адрес до установки.
- В стенде используются учебные пароли. Для рабочей системы их нужно хранить вне playbook.
- Диапазон UID и GID FreeIPA выбирает при установке, поэтому числовые значения в выводе могут отличаться при новом запуске.
