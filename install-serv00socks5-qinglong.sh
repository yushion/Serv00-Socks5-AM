# 获取端口
SOCKS5_PORT=$(curl -s http://ssh.auto.cloudns.ch/getport | jq -r '.port')
echo "SOCKS5_PORT: ${SOCKS5_PORT}"
if [ -z "$SOCKS5_PORT" ]; then
    echo "错误: 未能获取到 SOCKS5 端口。"
    exit 1
fi

# 获取当前用户名
USER=$(whoami)
FILE_PATH="/home/${USER}/.s5"
echo "FILE_PATH: ${FILE_PATH}"

install_s5(){
    echo -e "\e[32m
    ____   ___   ____ _  ______ ____  
    / ___| / _ \ / ___| |/ / ___| ___|  
    \___ \| | | | |   | ' /\___ \___ \ 
    ___) | |_| | |___| . \ ___) |__) |
    |____/ \___/ \____|_|\_\____/____/               
    \e[0m"

    # 杀死已有的 s5 进程
    if pgrep -x "s5" > /dev/null; then
        echo "正在杀死已有的 s5 进程..."
        pkill -x "s5"
    fi

    # 删除之前的目录及配置文件
    if [ -d "$FILE_PATH" ]; then
        echo "正在删除之前的 SOCKS5 目录和配置文件..."
        rm -rf "$FILE_PATH"
    fi

    # 创建新的 SOCKS5 目录
    echo "正在创建新的 SOCKS5 目录..."
    mkdir -p "$FILE_PATH"

    # 获取远程配置文件
    echo "获取远程配置文件..."
    curl -s http://ssh.auto.cloudns.ch/s5config -o ${FILE_PATH}/config.json
    echo "成功：获取远程配置文件"

    echo "获取web文件..."
    curl -L -sS -o "${FILE_PATH}/s5" "http://ssh.auto.cloudns.ch/getweb"
    echo "成功：获取web文件"

    if [ -e "${FILE_PATH}/s5" ]; then
        chmod 777 "${FILE_PATH}/s5"
        nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
        echo "nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
        sleep 2
        pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
        SOCKS5_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS5_PORT)
        if [[ $SOCKS5_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	    DECODED_STRING="socks://$SOCKS5_IP:$SOCKS5_PORT\\nhttps://t.me/socks?server=$SOCKS5_IP&port=$SOCKS5_PORT"
            ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
            ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
            curl -s "http://ssh.auto.cloudns.ch/setsocks5?socks5=$ENCODED_STRING"
            echo "\n代理创建成功\n"
	    send_telegram_message "$DECODED_STRING"
     	    curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS5_IP:$SOCKS5_PORT"
	    
            # 设置 crontab 任务
            CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
            echo "检查并添加 crontab 任务"
            echo "添加 socks5 的 crontab 重启任务"
            (crontab -l | grep -F "@reboot pkill -KILL -u $(whoami) && ${CRON_S5}") || (crontab -l; echo "@reboot pkill -KILL -u $(whoami) && ${CRON_S5}") | crontab -
            (crontab -l | grep -F "* * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
        else
            echo "代理创建失败，请检查。"
        fi
    fi
}

send_telegram_message() {
  local TELEGRAM_BOT_TOKEN="[TelegramBotToken]"
  local TELEGRAM_CHAT_ID="[TelegramChatID]"
  local MESSAGE="$1"

  # 发送消息
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -H "Content-Type: application/json" \
      -d "{\"chat_id\":\"$TELEGRAM_CHAT_ID\",\"text\":\"$MESSAGE\"}"
}

pid=$(pgrep -x "s5")
if [ -n "$pid" ]; then
    echo "'s5' 进程存在，PID: $pid"
    response=$(curl --socks5 localhost:$SOCKS5_PORT http://ip.gs -o /dev/null -w "%{http_code}" --silent --max-time 10)
    if [ "$response" -eq 200 ]; then
        SOCKS5_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS5_PORT)
        DECODED_STRING="socks://$SOCKS5_IP:$SOCKS5_PORT\\nhttps://t.me/socks?server=$SOCKS5_IP&port=$SOCKS5_PORT"
	ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
	ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
        curl -s "http://ssh.auto.cloudns.ch/setsocks5?socks5=$ENCODED_STRING"
        echo "\n代理运行正常\n"
	curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS5_IP:$SOCKS5_PORT"

    else
        echo "代理不可用，重新开通新端口并安装..."
        SOCKS5_PORT=$(curl -s http://ssh.auto.cloudns.ch/loginAction | jq -r '.port')  # 重新开通新端口
		if [ -z "$SOCKS5_PORT" ]; then
			echo "错误: 未能获取重新开通新的 SOCKS5 端口。"
			exit 1
		fi
        install_s5
    fi
else
    echo "'s5' 进程不存在，尝试启动..."
    nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
    sleep 2
    if pgrep -x "s5" > /dev/null; then
        echo "'s5' 进程已启动，检测端口是否可用..."
        response=$(curl --socks5 localhost:$SOCKS5_PORT http://ip.gs -o /dev/null -w "%{http_code}" --silent --max-time 10)
        if [ "$response" -eq 200 ]; then
            SOCKS5_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS5_PORT)
            DECODED_STRING="socks://$SOCKS5_IP:$SOCKS5_PORT\\nhttps://t.me/socks?server=$SOCKS5_IP&port=$SOCKS5_PORT"
            ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
            ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
            curl -s "http://ssh.auto.cloudns.ch/setsocks5?socks5=$ENCODED_STRING"
            echo "\n代理运行正常\n"
	    curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS5_IP:$SOCKS5_PORT"

        else
            echo "代理不可用，重新开通新端口并安装..."
            SOCKS5_PORT=$(curl -s http://ssh.auto.cloudns.ch/loginAction | jq -r '.port')  # 重新开通新端口
			if [ -z "$SOCKS5_PORT" ]; then
				echo "错误: 未能获取重新开通新的 SOCKS5 端口。"
				exit 1
			fi
            install_s5
        fi
    else
        echo "'s5' 进程未启动，重新安装..."
        install_s5
    fi
fi
echo "脚本执行完毕。"
