# OutlineBackup
Требования
 ОС: Debian 11 или выше
 Готовый телеграм-бот с API ключом
 Чат( или группа) в котором с ботом было взаимодействие (/start)

Для установки используйте команду 
    Debian 11 +
    

        apt install curl && curl -o install.sh https://raw.githubusercontent.com/Djemchik/OutlineBackup/main/install.sh && sh install.sh

Ubuntu 22.04 +

    
        apt install curl && curl https://raw.githubusercontent.com/Djemchik/OutlineBackup/main/install.sh > install.sh && sh install.sh
    
Для проверки используйте команду
    systemctl start backup_script.service

