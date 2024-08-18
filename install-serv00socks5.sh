# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |
 |____/ \___/ \____|_|\_\____/____/               

\e[0m"

# 获取当前用户名
USER=$(whoami)
FILE_PATH="/home/${USER}/.s5"
SOCKS5_PORT=${{env.PORT}}

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
curl -s https://serv00socks5.yxyfffass.workers.dev/s5config -o ${FILE_PATH}/config.json

# install_socks5 函数定义
install_socks5(){
  curl -L -sS -o "${FILE_PATH}/s5" "https://serv00socks5.yxyfffass.workers.dev/getweb"

  if [ -e "${FILE_PATH}/s5" ]; then
    chmod 777 "${FILE_PATH}/s5"
    nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
    echo "nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
    sleep 2
    pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
    CURL_OUTPUT=$(curl -s ip.sb --socks5 localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "代理创建成功，返回的IP是: $CURL_OUTPUT"
      echo "socks://$CURL_OUTPUT:$SOCKS5_PORT"
    else
      echo "代理创建失败，请检查自己输入的内容。"
    fi
  fi
}

# 安装 SOCKS5 代理
install_socks5

# 设置 crontab 任务
CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
echo "检查并添加 crontab 任务"
echo "添加 socks5 的 crontab 重启任务"
(crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") || (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") | crontab -
(crontab -l | grep -F "* * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -

echo "脚本执行完成。"
