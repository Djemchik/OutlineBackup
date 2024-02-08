#!/bin/bash

# Функция для определения текущей даты в формате ЧЧММГГГГ
get_date() {
    date +'%d%m%Y'
}

# Функция для получения IP адреса через интернет-сервис
get_ip_info() {
    ip_info=$(curl -s ipinfo.io/"$1"/country)
    if [ -z "$ip_info" ]; then
        echo "Failed to get IP information"
        exit 1
    else
        echo "$ip_info"
    fi
}

get_ip_address() {
    ip=$(curl -s ifconfig.co)
    if [ -z "$ip" ]; then
        echo "Failed to get IP address"
        exit 1
    else
        ip_info=$(get_ip_info "$ip")
        echo "$ip $ip_info"
    fi
}

# Путь к папке, которую нужно архивировать
SOURCE_DIR="/opt/outline"

# Получаем текущую дату и форматируем её
DATE=$(get_date)

# Создаем имя архива
ARCHIVE_NAME="backup_$DATE.zip"

# Архивируем содержимое папки
zip -r "$ARCHIVE_NAME" "$SOURCE_DIR"

# Определяем IP адрес
IP=$(get_ip_address)

#Определение страны от пользователя
Country="none"

# Токен вашего бота в Telegram
BOT_TOKEN="none"

# ID чата или группы, в которую нужно отправить архив
CHAT_ID="none"

# URL-адрес для отправки сообщения в Telegram
TELEGRAM_API_URL="https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

# Преобразуем заголовок (caption) в UTF-8
CAPTION="Местоположение: по данным ifconfig.co = $IP 
По данным пользователя: $Country
"

# Отправляем архив в Telegram вместе с сообщением об IP адресе отправителя
curl -X POST "$TELEGRAM_API_URL" \
     -F "chat_id=$CHAT_ID" \
     -F "document=@$ARCHIVE_NAME" \
     -F "caption=$CAPTION" \
     --header "Content-Type: multipart/form-data; charset=utf-8"

# Удаляем временный архив
rm "$ARCHIVE_NAME"
