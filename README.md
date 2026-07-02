## Задание 11

### 1. Nginx на нестандартном порту

Порт:

```bash
4881
```

Конфиг nginx:

```bash
vi /etc/nginx/nginx.conf
```

```nginx
server {
    listen 4881;
}
```

Проверка запрета SELinux:

```bash
systemctl restart nginx
ausearch -m AVC -ts recent
```

В audit видим запрет `name_bind` для `httpd_t` на нестандартный порт.

#### Способ 1. setsebool

Реализация:

```bash
setsebool -P nis_enabled on
systemctl restart nginx
```

Демонстрация:

```bash
getenforce
Enforcing

getsebool nis_enabled
nis_enabled --> on

ss -ltnp | grep 4881
LISTEN 0 128 *:4881 *:* users:(("nginx",pid=...,fd=...))

curl -I http://127.0.0.1:4881
HTTP/1.1 200 OK
```

#### Способ 2. Добавление порта в тип http_port_t

Реализация:

```bash
semanage port -a -t http_port_t -p tcp 4881
systemctl restart nginx
```

Демонстрация:

```bash
getenforce
Enforcing

semanage port -l | grep http_port_t
http_port_t tcp 4881, 80, 81, 443, 488, 8008, 8009, 8443

ss -ltnp | grep 4881
LISTEN 0 128 *:4881 *:* users:(("nginx",pid=...,fd=...))

curl -I http://127.0.0.1:4881
HTTP/1.1 200 OK
```

#### Способ 3. Модуль SELinux

Реализация:

```bash
systemctl restart nginx
ausearch -m AVC,USER_AVC -ts recent -c nginx --raw > nginx_avc.log
audit2allow -M nginx_bind_nonstandard < nginx_avc.log
semodule -i nginx_bind_nonstandard.pp
systemctl restart nginx
```

Демонстрация:

```bash
getenforce
Enforcing

semodule -l | grep nginx_bind_nonstandard
nginx_bind_nonstandard

ss -ltnp | grep 4881
LISTEN 0 128 *:4881 *:* users:(("nginx",pid=...,fd=...))

curl -I http://127.0.0.1:4881
HTTP/1.1 200 OK
```

### 2. DNS

Стенд:

```bash
cd selinux_dns_problems
vagrant up
```

Причина:

```bash
/etc/named/dynamic
```

Динамическая зона лежит в каталоге с неверным SELinux-контекстом. `named` не может создать journal-файл зоны, из-за этого `nsupdate` возвращает `SERVFAIL`.

Проверка причины:

```bash
vagrant ssh ns01
ls -lZ /etc/named/dynamic
ausearch -m AVC -ts recent
```

Реализация в `provisioning/playbook.yml`:

```bash
semanage fcontext -a -t named_cache_t '/etc/named/dynamic(/.*)?' || semanage fcontext -m -t named_cache_t '/etc/named/dynamic(/.*)?'
restorecon -Rv /etc/named/dynamic
```

Демонстрация:

```bash
vagrant ssh ns01
ls -lZ /etc/named/dynamic
system_u:object_r:named_cache_t:s0 named.ddns.lab

vagrant ssh client
nsupdate -k /etc/named.zonetransfer.key
server 192.168.50.10
zone ddns.lab
update add www.ddns.lab. 60 A 192.168.50.15
send
quit

dig @192.168.50.10 www.ddns.lab +short
192.168.50.15
```
