## Задание 28. Репликация MySQL

### Что сделано

Поднят стенд из двух виртуальных машин:

- `master` — `192.168.56.101`;
- `slave` — `192.168.56.102`.

На мастере создана база `bet` и загружен файл `bet.dmp`. Настроена GTID-репликация на слейв. На слейве разрешена репликация пяти таблиц из задания, а `events_on_demand` и `v_same_event` исключены фильтрами.

### Запуск

```bash
vagrant up
```

На первом запуске Vagrant устанавливает MySQL, копирует конфигурацию, загружает базу на мастер, подготавливает слейв и запускает репликацию.

### Конфигурация

В конфигурации мастера включены:

- `server-id = 1`;
- бинарный журнал;
- `gtid-mode = ON`;
- `enforce-gtid-consistency = ON`.

В конфигурации слейва используется другой идентификатор `server-id = 2`. Фильтры `replicate-ignore-table` исключают две таблицы, которые не должны реплицироваться.

Подключение к мастеру выполняется пользователем `repl` с `SOURCE_AUTO_POSITION=1`, поэтому координаты бинарного журнала вручную не задаются.

### Проверка

Список таблиц на мастере:

```text
Tables_in_bet
bookmaker
competition
events_on_demand
market
odds
outcome
v_same_event
```

Список таблиц на слейве:

```text
Tables_in_bet
bookmaker
competition
market
odds
outcome
```

Состояние репликации:

```text
Replica_IO_Running: Yes
Replica_SQL_Running: Yes
Auto_Position: 1
Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
```

Для проверки передачи изменения на мастере выполнена запись:

```sql
INSERT INTO bet.bookmaker (id, bookmaker_name)
VALUES (1, '1xbet');
```

После этого на слейве:

```sql
SELECT * FROM bet.bookmaker WHERE id = 1;
```

```text
id  bookmaker_name
1   1xbet
```

Запись из `bookmaker` появилась на слейве, значит GTID-репликация для этой таблицы работает.

### Файлы

- `Vagrantfile` — описание двух ВМ и автоматическая настройка MySQL;
- `configs/master.cnf` — конфигурация мастера;
- `configs/slave.cnf` — конфигурация слейва и фильтры таблиц;
- `bet.dmp` — исходный дамп базы.

Используется публичный box `bento/ubuntu-24.04`. При первом запуске Vagrant загрузит его автоматически.
