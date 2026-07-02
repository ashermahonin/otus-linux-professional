## Задание 13

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/13-vagrant

### Запуск

```bash
vagrant up
```

### Проверка дисков

```bash
vagrant ssh -c "df -h"
```

![image](image.png)

### Проверка проброса порта

Для Linux-хоста:

```bash
netstat -tulpn | grep 8080
```

На текущем хосте macOS:

```bash
netstat -anv -p tcp | grep 8080
```

![image-1](image-1.png)

### Что сделано

В `Vagrantfile` создана ВМ с 1024 МБ памяти, добавлены два диска по 1 ГБ, настроен проброс `80 -> 8080`. Провижининг форматирует диски в `ext4`, создает `/mnt/disk1` и `/mnt/disk2`, монтирует их и добавляет записи в `/etc/fstab`.
