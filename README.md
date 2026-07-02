## Задание 14

### Репозиторий

https://github.com/ashermahonin/otus-linux-professional/tree/14-docker

### Docker Hub

https://hub.docker.com/r/damiansargers1/otus-nginx

### Установка Docker на Ubuntu

Документация: https://docs.docker.com/engine/install/ubuntu/

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

Проверка Compose:

```bash
docker compose version
```

### Сборка образа

```bash
docker build -t damiansargers1/otus-nginx:14-docker .
docker run -d --name otus-nginx -p 8082:80 damiansargers1/otus-nginx:14-docker
curl http://127.0.0.1:8082
docker push damiansargers1/otus-nginx:14-docker
```

![image](image.png)

![image-1](image-1.png)

### Образ и контейнер

Образ - шаблон файловой системы и настроек приложения. Он неизменяемый и используется для создания контейнеров.

Контейнер - запущенный экземпляр образа. У него есть процесс, состояние выполнения, сеть и writable layer.

### Можно ли в контейнере собрать ядро?

Можно, если в контейнер добавить компиляторы, зависимости и исходники ядра. Но контейнер использует ядро хоста, поэтому собранное ядро внутри контейнера не станет ядром этого контейнера. Для загрузки нового ядра нужна отдельная VM или физическая машина.

### Что сделано

Создан кастомный образ nginx на базе `nginx:alpine`. В образ добавлена измененная страница `index.html`, после запуска контейнер отдает ее через nginx.
