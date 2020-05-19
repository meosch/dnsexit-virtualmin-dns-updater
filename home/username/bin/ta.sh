#!/bin/bash
# Send an alert on Telegram to Frederick's shell
# For testing. First line outputs line numbers.
# Second line says to output what is going on in script
#set -x
PS4=':${LINENO}+'

# See https://github.com/fabianonline/telegram.sh
# for how to create a bot and configure this script.

token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
chat_id="##########"
telegram_url="https://api.telegram.org/bot$token/sendMessage"

#emoticon " 😃"
#emoticon " 💥"
emoticon="️ 🖥️"
texttosend="$emoticon $1"
curl -s -X POST $telegram_url -d chat_id=$chat_id -d text="$texttosend" &>/dev/null
