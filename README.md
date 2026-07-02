## Задание 12

### Файлы стенда

![image](image.png)

### Запуск стенда

```bash
vagrant up
```

![image-1](image-1.png)

### Проверка nginx на 8080

```bash
curl -sS -i http://127.0.0.1:8080
```

![image-2](image-2.png)

### Проверка systemd и порта

```bash
vagrant ssh -c "systemctl is-enabled nginx"
vagrant ssh -c "sudo ss -ltnp | grep ':8080'"
```

![image-3](image-3.png)

### Условия Ansible

Использованы `apt`, `template`, переменная `nginx_listen_port: 8080`, `notify`, `systemd enabled`.

![image-4](image-4.png)
