#!/bin/bash

# Запрос прав суперпользователя
sudo -v

# Устанавливаем необходимые пакеты
apt update && apt install sudo
sudo apt update
sudo apt install -y ntp zip jq curl

echo "Удаляем предыдущии версии"
rm -f -r /tmp/backup.sh
rm -f -r /tmp/backup_modified.sh
# Запрос BOT_TOKEN
read -p "Введите BOT_TOKEN: " BOT_TOKEN
read -p "Введите страну нахождения сервера: " Country

# Запрашиваем список чатов
response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

# Проверка наличия ошибок в ответе
if echo "$response" | jq -e '.ok == false' >/dev/null; then
    echo "Ошибка: Не удалось получить список чатов."
    exit 1
fi

# Получаем информацию о чатах
chat_info=$(echo "$response" | jq -r '.result[].message.chat | "\(.id) \(.title)"')

# Инициализируем переменную для номера чата
chat_number=1

# Выводим доступные чаты
echo "Доступные чаты:"
echo "$chat_info" | while IFS= read -r line; do
    echo "[$chat_number] $line"
    chat_number=$((chat_number+1))
done

# Предоставление пользователю выбора чата или возможности вручную ввести CHAT_ID
read -p "Выберите чат (введите номер из списка или введите 0, чтобы ввести вручную): " selected_chat_number

# Проверка, был ли введен 0 для вручную введенного CHAT_ID
if [ "$selected_chat_number" -eq 0 ]; then
    read -p "Введите CHAT_ID: " CHAT_ID
else
    # Получаем ID выбранного чата
    selected_chat_id=$(echo "$chat_info" | sed -n "${selected_chat_number}p" | awk '{print $1}')
    CHAT_ID="$selected_chat_id"
fi

# Скачиваем скрипт backup.sh
wget -O /tmp/backup.sh https://github.com/Djemchik/OutlineBackup/raw/main/backup.sh



# Устанавливаем Московскую временную зону
sudo timedatectl set-timezone Europe/Moscow

# Копируем скрипт в каталог /tmp
cp /tmp/backup.sh /tmp/backup_modified.sh

# Редактирование скрипта backup.sh
sed -i "s/CHAT_ID=\"[^\"]*\"/CHAT_ID=\"$CHAT_ID\"/" /tmp/backup_modified.sh
sed -i "s/BOT_TOKEN=\"[^\"]*\"/BOT_TOKEN=\"$BOT_TOKEN\"/" /tmp/backup_modified.sh
sed -i "s/Country=\"[^\"]*\"/Country=\"$Country\"/" /tmp/backup_modified.sh

# Проверка формата времени
validate_time() {
    local time_pattern="^[0-9]+$"
    if ! [ "$1" -ge 0 ] || ! [ "$1" -le "$2" ]; then
        echo "Ошибка: Неверный формат времени. $3 должны быть в диапазоне от 00 до $2."
        exit 1
    fi
}

chmod +x /tmp/backup_modified.sh


# Запрос времени для запуска скрипта
read -p "Введите часы (от 00 до 23): " CRON_HOUR
validate_time "$CRON_HOUR" 23 "Часы"

# Запрос времени для запуска скрипта
read -p "Введите минуты (от 00 до 59): " CRON_MINUTE
validate_time "$CRON_MINUTE" 59 "Минуты"

# Создание службы systemd
sudo tee /etc/systemd/system/backup_script.service > /dev/null <<EOF
[Unit]
Description=Backup Script

[Service]
Type=simple
ExecStart=/bin/bash /tmp/backup_modified.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Создание таймера systemd
sudo tee /etc/systemd/system/backup_script.timer > /dev/null <<EOF
[Unit]
Description=Run backup_script.service every day at HH:MM

[Timer]
OnCalendar=*-*-* $CRON_HOUR:$CRON_MINUTE:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Перезагрузка конфигурации systemd
sudo systemctl daemon-reload

# Активация таймера
sudo systemctl enable --now backup_script.timer

# Проверка успешности активации
if systemctl is-active --quiet backup_script.timer; then
    echo "Таймер успешно настроен."
else
    echo "Ошибка: Не удалось активировать таймер."
    exit 1
fi

# Проверка статуса службы
if systemctl is-active --quiet backup_script.service; then
    echo "Служба успешно запущена."
else
    echo "Служба успешно запущена Всё чётко."
    
fi

echo "Установка завершена."
