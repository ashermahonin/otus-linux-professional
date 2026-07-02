## Задание 15

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/15-prometheus

### Запуск

```bash
docker compose up -d
```

### Проверка

```bash
docker compose ps
curl http://127.0.0.1:9091/-/ready
```

### Grafana

```bash
http://127.0.0.1:3002/d/aslan-prometheus
```

![image](image.png)

### Что сделано

Настроен стенд `prometheus + grafana + node-exporter`. В Grafana создан dashboard `Аслан - Prometheus` с 4 графиками: память, процессор, диск, сеть.
