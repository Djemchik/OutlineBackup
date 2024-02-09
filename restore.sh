#!/bin/bash

# Путь к файлу backup.sh
BACKUP_SCRIPT_PATH="/opt/backup.sh"

# Проверяем, существует ли файл backup.sh
if [ -f "$BACKUP_SCRIPT_PATH" ]; then
    # Получаем переменные BOT_TOKEN, CHAT_ID и Country из файла backup.sh
    while IFS= read -r line; do
        if [[ $line == "BOT_TOKEN="* ]]; then
            BOT_TOKEN="${line#*=}"
        elif [[ $line == "CHAT_ID="* ]]; then
            CHAT_ID="${line#*=}"
        elif [[ $line == "Country="* ]]; then
            Country="${line#*=}"
        fi
    done < "$BACKUP_SCRIPT_PATH"
else
    echo "Файл backup.sh не найден в указанной директории: $BACKUP_SCRIPT_PATH"
    exit 1
fi

# Проверяем, установлен ли unzip
if ! command -v unzip &> /dev/null; then
    echo "Утилита unzip не установлена. Установите её перед продолжением."
    exit 1
fi

# Запрос API токена у пользователя
read -p "Введите API токен вашего Telegram бота: " BOT_TOKEN

# URL для запроса списка файлов
TELEGRAM_API_URL="https://api.telegram.org/bot$BOT_TOKEN/getUpdates"

# Отправляем запрос на получение обновлений бота
response=$(curl -s "$TELEGRAM_API_URL")
latest_file=$(echo "$response" | jq -r --arg CHAT_ID "$CHAT_ID" --arg COUNTRY "$Country" '.result[] | select(.message.document.chat.id == ($CHAT_ID | tonumber) and .message.document.file_name | endswith(".zip") and .message.document.file_name | contains($COUNTRY)) | .message.document')

if [ -n "$latest_file" ]; then
    file_name=$(echo "$latest_file" | jq -r '.file_name')

    echo "Описание поста: $(echo "$latest_file" | jq -r '.message.text')"
    echo "Название архива: $file_name"

    # Запрос подтверждения перед загрузкой
    read -p "Хотите загрузить и распаковать этот архив? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Операция отменена."
        exit 1
    fi

    # Загружаем файл
    file_id=$(echo "$latest_file" | jq -r '.file_id')
    file_path=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getFile?file_id=$file_id" | jq -r '.result.file_path')
    file_url="https://api.telegram.org/file/bot$BOT_TOKEN/$file_path"
    curl -o "$file_name" "$file_url"

    # Распаковываем архив
    unzip -q "$file_name" -d /opt/outline

    # Удаляем загруженный архив
    rm "$file_name"
    echo "Архив успешно загружен и распакован!"
else
    echo "Не удалось найти подходящий файл архива."
fi
