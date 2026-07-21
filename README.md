## Задание 25. VLAN и LACP

### Текст задания

В тестовой сети Office1 нужно добавить четыре узла с дополнительными интерфейсами и одинаковыми адресами в разных VLAN:

- `testClient1` и `testClient2` с адресом `10.10.10.254`;
- `testServer1` и `testServer2` с адресом `10.10.10.1`;
- `testClient1` должен работать только с `testServer1`, а `testClient2` только с `testServer2`.

Между `centralRouter` и `inetRouter` нужно создать два линка и объединить их в LACP bond. Работа bond проверяется при отключении одного интерфейса.

### Файлы

`Vagrantfile` поднимает семь ВМ. Четыре VLAN-узла подключены к общей внутренней сети `testLAN`. Для LACP созданы две пары отдельных внутренних сетей и ВМ `lacpSwitch`.

`ansible/playbook.yml` настраивает VLAN 10, VLAN 20 и LACP bond в режиме `802.3ad`, затем проверяет связь и отказ одного линка.

### Схема сети

~~~text
testClient1  10.10.10.254/24  eth1.10 --- testLAN, VLAN 10 --- eth1.10  10.10.10.1/24  testServer1

testClient2  10.10.10.254/24  eth1.20 --- testLAN, VLAN 20 --- eth1.20  10.10.10.1/24  testServer2

centralRouter  eth1 --- central-link1 --- eth1  lacpSwitch  eth3 --- inet-link1 --- eth1  inetRouter
               eth2 --- central-link2 --- eth2              eth4 --- inet-link2 --- eth2
                 \____________________________ bond0 ____________________________/
                 172.16.25.2/30                         172.16.25.1/30
~~~

### Реализация

На `testClient1` и `testServer1` создан интерфейс `vlan10`. На `testClient2` и `testServer2` создан `vlan20`. Родительский интерфейс `eth1` адреса не получает.

На маршрутизаторах `eth1` и `eth2` объединены в `bond0` с режимом `802.3ad`, быстрыми LACP-пакетами и проверкой линка каждые 100 мс. На `lacpSwitch` Open vSwitch принимает LACP от обоих bond и передает трафик между ними. У коммутатора нет IP-адреса.

Для передачи LACP-кадров через VirtualBox на линках bond разрешен promisc-режим: для адаптеров ВМ в `Vagrantfile` и для гостевых интерфейсов после применения netplan.

### Команды и вывод

Запуск стенда:

~~~bash
vagrant up
~~~

Проверка VLAN 10:

~~~bash
vagrant ssh testClient1 -c 'ping -c 2 10.10.10.1'
~~~

Проверка VLAN 20:

~~~bash
vagrant ssh testClient2 -c 'ping -c 2 10.10.10.1'
~~~

Проверка bond и отключения первого линка:

~~~bash
vagrant ssh centralRouter -c 'cat /proc/net/bonding/bond0'
vagrant ssh centralRouter -c 'sudo ip link set eth1 down'
vagrant ssh centralRouter -c 'ping -I bond0 -c 2 172.16.25.1'
~~~

После запуска стенда получены результаты:

~~~text
testClient1 -> 10.10.10.1: 2 packets transmitted, 2 received, 0% packet loss
testClient2 -> 10.10.10.1: 2 packets transmitted, 2 received, 0% packet loss
centralRouter -> 172.16.25.1 через bond0: 2 packets transmitted, 2 received, 0% packet loss
после отключения eth1: 2 packets transmitted, 2 received, 0% packet loss
~~~

В выводе `cat /proc/net/bonding/bond0` подтверждены режим `IEEE 802.3ad Dynamic link aggregation`, быстрый LACP и оба интерфейса `eth1` и `eth2` в составе bond.

### Заметки

- У адресов `10.10.10.1` и `10.10.10.254` есть по две копии, но VLAN разделяют широковещательные домены, поэтому конфликта адресов нет.
- LACP сохраняет связь при отключении одного линка. Один TCP-поток не обязан использовать суммарную скорость обоих линков: выбор линии зависит от хеша потока.
- LACP требует партнера, который участвует в обмене служебными кадрами. В VirtualBox эту роль выполняет `lacpSwitch` с Open vSwitch.
