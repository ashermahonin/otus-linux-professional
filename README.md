## Работа с пакетами

1. создать свой RPM (можно взять свое приложение, либо собрать к примеру Apache с определенными опциями);
2. cоздать свой репозиторий и разместить там ранее собранный RPM;
3. реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий.

## Включение CRB и установка инструментов:

```bash
dnf -y install dnf-plugins-core || true
dnf -y config-manager --set-enabled crb || true
dnf -y makecache


dnf -y install wget rpmdevtools rpm-build createrepo_c yum-utils cmake gcc git nano which tar gzip make dnf-plugins-core redhat-rpm-config

rpmdev-setuptree
ls -la ~/rpmbuild
```
## Скачивание SRPM Nginx
```bash
mkdir -p /root/rpm && cd /root/rpm
yumdownloader --source nginx
ls -la /root/rpm | sed -n '1,200p'
```

## Установка SRPM и установка зависимостей сборки (builddep)
### Распаковка spec/sources в ~/rpmbuild и установка зависимостей:

```bash
cd /root/rpm && rpm -Uvh ./*.src.rpm
dnf -y builddep nginx || dnf -y builddep /root/rpmbuild/SPECS/nginx.spec
```

## Получение исходников ngx_brotli и сборка brotli
### Клонирование репозитория с сабмодулями:

```bash
cd /root && rm -rf /root/ngx_brotli || true
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
ls -la /root/ngx_brotli | sed -n '1,120p'
```

## Сборка brotli (как зависимость внутри ngx_brotli) через cmake:

```bash
cd /root/ngx_brotli/deps/brotli && rm -rf out && mkdir -p out && cd out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_C_FLAGS='-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections' \
  -DCMAKE_CXX_FLAGS='-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections' \
  -DCMAKE_INSTALL_PREFIX=./installed .
cmake --build . --config Release -j 2 --target brotlienc
```

## Правка SPEC: подключение модуля ngx_brotli

### Сделан бэкап spec и добавлена строка --add-module=/root/ngx_brotli \ в секцию %configure:

```bash
cp -a /root/rpmbuild/SPECS/nginx.spec /root/rpmbuild/SPECS/nginx.spec.bak.2026-02-16_233521

awk '
  BEGIN{done=0}
  {
    print
    if(done==0 && $0 ~ /^%configure/){
      print "        --add-module=/root/ngx_brotli \\\\"
      done=1
    }
  }' /root/rpmbuild/SPECS/nginx.spec > /root/rpmbuild/SPECS/nginx.spec.new \
  && mv -f /root/rpmbuild/SPECS/nginx.spec.new /root/rpmbuild/SPECS/nginx.spec

grep -n "add-module=/root/ngx_brotli" -n /root/rpmbuild/SPECS/nginx.spec || true
```

## Сборка RPM

```bash
cd /root/rpmbuild/SPECS
rpmbuild -ba nginx.spec -D 'debug_package %{nil}'
```

## Установка собранных RPM и проверка Nginx
### Установка локально из каталога с пакетами:

```bash
cd /root/rpmbuild/RPMS/x86_64
dnf -y localinstall ./*.rpm

systemctl enable --now nginx
systemctl --no-pager status nginx | sed -n '1,120p'
```


