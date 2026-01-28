## Задание 3
Создание PV, VG, LV

![image-1](image-1.png)

Создание файловой системы и монтирование

![image-2](image-2.png)

Копирование root

![image-3](image-3.png)

Обновление загрузчика

![image-4](image-4.png)

Создание нового LV

![image-5](image-5.png)

Файловая система

![image-6](image-6.png)

Копирование root

![image-7](image-7.png)

Обновление загрузчика grub

![image-8](image-8.png)

Удаление старого root и переименование

![image-9](image-9.png)

Выделение /var в mirror cоздание PV и VG

![image-10](image-10.png)

Создание mirror LV

![image-11](image-11.png)

Файловая система

![image-12](image-12.png)

Перенос /var и fstab

![image-13](image-13.png)

Выделение /home в отдельный том и создание LV

![image-14](image-14.png)

Файловая система

![image-15](image-15.png)

Перенос /home и fstab

![image-16](image-16.png)

СНЭПШОТЫ

Генерация файлов и созд снепшота (touch /home/file{1..20})

![image-17](image-17.png)

далее удаляем файлы (rm -f /home/file{1..20})
 и воостанавливаемся из снепшота

![image-18](image-18.png)