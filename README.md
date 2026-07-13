## Задание 21. Iptables

### Файлы

`Vagrantfile` создает `inetRouter`, `centralRouter`, `centralServer` и `inetRouter2`.

`ansible/playbook.yml` настраивает маршруты, iptables, nginx и скрипт knocking.

### Запуск

```bash
vagrant up
```

### Проверка

Проверка SSH через knock script:

```bash
vagrant ssh centralRouter -c "sudo -u vagrant /home/vagrant/knock.sh hostname"
```

В ответ будет `inet-router`.

Проверка nginx через `inetRouter2` с хостовой машины:

```bash
curl http://192.168.56.21:8080
```

В ответ будет `nginx on centralServer`.
