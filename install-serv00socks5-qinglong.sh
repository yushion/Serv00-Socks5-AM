# 获取端口
SOCKS_PORT=$(curl -s http://ssh.auto.cloudns.ch/getport?user=[username] | jq -r '.port')
echo "SOCKS_PORT 代理端口号: ${SOCKS_PORT}"
if [ -z "$SOCKS_PORT" ] || [ "$SOCKS_PORT" = "null" ]; then
	SOCKS_PORT=$(curl -s http://ssh.auto.cloudns.ch/loginAction?user=[username] | jq -r '.port')  # 重新开通新端口
	echo "SOCKS_PORT 重新开通新代理端口号: ${SOCKS_PORT}"
	if [ -z "$SOCKS_PORT" ] || [ "$SOCKS_PORT" = "null" ]; then
		echo "错误: 未能获取重新开通新的 SOCKS5 端口。"
		exit 0
	fi
fi

# 获取当前用户名
USER=$(whoami)
FILE_PATH="/home/${USER}/.[socksname]"
echo "FILE_PATH: ${FILE_PATH}"

install_socks(){
    echo -e "\e[32m
    ____   ___   ____ _  ______ ____  
    / ___| / _ \ / ___| |/ / ___| ___|  头顶着太阳
    \___ \| | | | |   | ' /\___ \___ \  梦想在远方
    ___) | |_| | |___| . \ ___) |__) |  漫天数星光
    |____/ \___/ \____|_|\_\____/____/  也为你而亮             
    \e[0m"

    # 杀死已有的 [socksname] 进程
    if pgrep -x "[socksname]" > /dev/null; then
        echo "正在杀死已有的 [socksname] 进程..."
        pkill -x "[socksname]"
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
    curl -s http://ssh.auto.cloudns.ch/s5config?user=[username] -o ${FILE_PATH}/config.json
    echo "成功：获取远程配置文件"

    echo "获取web文件..."
    curl -L -sS -o "${FILE_PATH}/[socksname]" "http://ssh.auto.cloudns.ch/getweb?user=[username]"
    echo "成功：获取web文件"

    if [ -e "${FILE_PATH}/[socksname]" ]; then
        chmod 777 "${FILE_PATH}/[socksname]"
        nohup ${FILE_PATH}/[socksname] -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
        echo "nohup ${FILE_PATH}/[socksname] -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
        sleep 2
        pgrep -x "[socksname]" > /dev/null && echo -e "\e[1;32m[socksname] is running\e[0m" || { echo -e "\e[1;35m[socksname] is not running, restarting...\e[0m"; pkill -x "[socksname]" && nohup "${FILE_PATH}/[socksname]" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m[socksname] restarted\e[0m"; }
        SOCKS_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS_PORT)
        if [[ $SOCKS_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	    DECODED_STRING="socks5://$SOCKS_IP:$SOCKS_PORT\\nhttps://t.me/socks?server=$SOCKS_IP&port=$SOCKS_PORT\\nhttps://t.me/socks?server=oliverzoe.serv00.net&port=$SOCKS_PORT"
            ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
            ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
            curl -s "http://ssh.auto.cloudns.ch/setsocks5?user=[username]&socks5=$ENCODED_STRING"
            echo "\n代理创建成功\n"
	    send_telegram_message "$DECODED_STRING"
     	    curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS_IP:$SOCKS_PORT"
	    
            # 设置 crontab 任务
            CRON_SOCKS="nohup ${FILE_PATH}/[socksname] -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
            echo "检查并添加 crontab 任务"
            echo "添加 [socksname] 的 crontab 重启任务"
            (crontab -l | grep -F "@reboot pkill -KILL -u $(whoami) && ${CRON_SOCKS}") || (crontab -l; echo "@reboot pkill -KILL -u $(whoami) && ${CRON_SOCKS}") | crontab -
            (crontab -l | grep -F "* * pgrep -x \"[socksname]\" > /dev/null || ${CRON_SOCKS}") || (crontab -l; echo "*/12 * * * * pgrep -x \"[socksname]\" > /dev/null || ${CRON_SOCKS}") | crontab -
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

pid=$(pgrep -x "[socksname]")
if [ -n "$pid" ]; then
    echo "'[socksname]' 进程存在，PID: $pid"
    response=$(curl --socks5 localhost:$SOCKS_PORT http://ip.gs -o /dev/null -w "%{http_code}" --silent --max-time 10)
    if [ "$response" -eq 200 ]; then
        SOCKS_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS_PORT)
        DECODED_STRING="socks5://$SOCKS_IP:$SOCKS_PORT\\nhttps://t.me/socks?server=$SOCKS_IP&port=$SOCKS_PORT\\nhttps://t.me/socks?server=oliverzoe.serv00.net&port=$SOCKS_PORT"
	ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
	ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
        curl -s "http://ssh.auto.cloudns.ch/setsocks5?user=[username]&socks5=$ENCODED_STRING"
        echo "\n代理运行正常\n"
	curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS_IP:$SOCKS_PORT"

    else
        echo "代理不可用，重新开通新端口并安装..."
        SOCKS_PORT=$(curl -s http://ssh.auto.cloudns.ch/loginAction?user=[username] | jq -r '.port')  # 重新开通新端口
		if [ -z "$SOCKS_PORT" ] || [ "$SOCKS_PORT" = "null" ]; then
			echo "错误: 未能获取重新开通新的 SOCKS5 端口。"
			exit 0
		fi
        install_socks
    fi
else
    echo "'[socksname]' 进程不存在，尝试启动..."
    nohup "${FILE_PATH}/[socksname]" -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
    sleep 2
    if pgrep -x "[socksname]" > /dev/null; then
        echo "'[socksname]' 进程已启动，检测端口是否可用..."
        response=$(curl --socks5 localhost:$SOCKS_PORT http://ip.gs -o /dev/null -w "%{http_code}" --silent --max-time 10)
        if [ "$response" -eq 200 ]; then
            SOCKS_IP=$(curl -s ip.sb --socks5 localhost:$SOCKS_PORT)
            DECODED_STRING="socks5://$SOCKS_IP:$SOCKS_PORT\\nhttps://t.me/socks?server=$SOCKS_IP&port=$SOCKS_PORT"
            ENCODED_STRING=$(echo -n $DECODED_STRING | jq -sRr @uri)
            ENCODED_STRING=$(echo "$ENCODED_STRING" | sed 's/%5Cn/%0A/g')
            curl -s "http://ssh.auto.cloudns.ch/setsocks5?user=[username]&socks5=$ENCODED_STRING"
            echo "\n代理运行正常\n"
	    curl -s "https://sctapi.ftqq.com/[SctapiToken].send?title=$USER:$SOCKS_IP:$SOCKS_PORT"

        else
            echo "代理不可用，重新开通新端口并安装..."
            SOCKS_PORT=$(curl -s http://ssh.auto.cloudns.ch/loginAction?user=[username] | jq -r '.port')  # 重新开通新端口
		if [ -z "$SOCKS_PORT" ] || [ "$SOCKS_PORT" = "null" ]; then
			echo "错误: 未能获取重新开通新的 SOCKS5 端口。"
			exit 0
		fi
            install_socks
        fi
    else
        echo "'[socksname]' 进程未启动，重新安装..."
        install_socks
    fi
fi
echo "脚本执行完毕。"
