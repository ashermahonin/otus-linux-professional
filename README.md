## Задание 20. DHCP и PXE

### Файлы

`Vagrantfile` создает PXE-сервер и клиент в сети `192.168.56.0/24`.

`ansible/playbook.yml` устанавливает и настраивает DHCP, TFTP, HTTP и NAT на PXE-сервере.

`ansible/files/user-data` содержит параметры автоматической установки Ubuntu 24.

### Запуск

Сначала запускается сервер, затем клиент:

```bash
vagrant up pxe_server
VAGRANT_EXPERIMENTAL=none_communicator vagrant up pxe_client
```

### Работа стенда

Клиент получает адрес от DHCP и загружает загрузчик, ядро и initrd через TFTP. Образ Ubuntu 24 берется из официального HTTP-репозитория. `user-data` и `meta-data` сервер отдает по HTTP из каталога `/autoinstall/`, поэтому установка проходит без вопросов в консоли.

Для выхода клиента к репозиториям PXE-сервер передает трафик из внутренней сети через свой NAT-интерфейс.

### Проверка

Проверка сервисов на PXE-сервере:

```bash
vagrant ssh pxe_server -c "systemctl is-active isc-dhcp-server tftpd-hpa apache2"
```

Проверка выдачи адреса и загрузчика:

```bash
vagrant ssh pxe_server -c "journalctl -u isc-dhcp-server -n 20"
```
