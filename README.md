## Задание 16. PAM

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/16-pam

### Задание

Ограничить доступ к системе для всех пользователей, кроме группы администраторов, в субботу и воскресенье. Если выходной день попал в список праздничных дней, вход должен быть разрешен.

### Файлы

`Vagrantfile` - создает виртуальную машину и настраивает PAM.

`README.md` - описание задания, команд и результата проверки.

### Запуск стенда

```bash
vagrant up
```

Вывод:

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-22.04'...
==> default: Setting the name of the VM: otus-16-pam
==> default: Forwarding ports...
    default: 22 (guest) => 2200 (host) (adapter 1)
==> default: Machine booted and ready!
==> default: Running provisioner: shell...
    default: Running: inline script
```

### Проверка пользователей и группы admin

```bash
vagrant ssh -c "getent group admin && id otus && id otusadm && id vagrant"
```

Вывод:

```text
admin:x:1001:otusadm,vagrant
uid=1001(otus) gid=1002(otus) groups=1002(otus)
uid=1002(otusadm) gid=1003(otusadm) groups=1003(otusadm),27(sudo),1001(admin)
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),110(lxd),1001(admin)
```

### Проверка подключения PAM

```bash
vagrant ssh -c "grep pam_weekend_check /etc/pam.d/sshd"
```

Вывод:

```text
account required pam_exec.so quiet /usr/local/bin/pam_weekend_check.sh
```

### Проверка списка праздничных дней

```bash
vagrant ssh -c "sudo cat /etc/security/pam_holidays"
```

Вывод:

```text
04-07-2026
```

### Проверка правил доступа

`0` означает, что доступ разрешен. `1` означает, что доступ запрещен.

```bash
vagrant ssh -c 'check_access() { label="$1"; user="$2"; weekday="$3"; day="$4"; sudo env PAM_USER="$user" PAM_TEST_WEEKDAY="$weekday" PAM_TEST_DATE="$day" /usr/local/bin/pam_weekend_check.sh; rc=$?; echo "$label=$rc"; }; check_access otus_subbota otus 6 11-07-2026; check_access admin_subbota otusadm 6 11-07-2026; check_access otus_prazdnik otus 6 04-07-2026; check_access otus_budni otus 1 06-07-2026'
```

Вывод:

```text
otus_subbota=1
admin_subbota=0
otus_prazdnik=0
otus_budni=0
```

Обычный пользователь `otus` не может войти в субботу `11-07-2026`. Пользователь `otusadm` входит в группу `admin`, поэтому ему вход разрешен даже в субботу. Дата `04-07-2026` есть в `/etc/security/pam_holidays`, поэтому в этот день обычный пользователь тоже может войти. В понедельник `06-07-2026` вход для `otus` разрешен.

### Проверка реального SSH-входа

Проверка выполнена `06-07-2026`, это понедельник.

```bash
sshpass -p otus ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2200 otus@127.0.0.1 'whoami && id -nG'
```

Вывод:

```text
otus
otus
```

### Особенности реализации

Проверка подключена к `sshd` в секции `account` через `pam_exec`.

Скрипт `/usr/local/bin/pam_weekend_check.sh` берет имя пользователя из `PAM_USER`. Если пользователь состоит в группе `admin`, вход разрешается сразу. Для остальных пользователей проверяется дата: суббота и воскресенье запрещены, но даты из `/etc/security/pam_holidays` считаются исключением.

Пользователь `vagrant` добавлен в `admin`, чтобы Vagrant мог подключаться к стенду в любой день.

### Заметки

Для проверки выходных и праздничных дней я использовал `PAM_TEST_WEEKDAY` и `PAM_TEST_DATE`. Так не нужно менять дату в виртуальной машине. При обычном входе по SSH эти переменные не задаются, скрипт берет текущую дату через `date`.
