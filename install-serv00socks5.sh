#!/bin/bash

# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           供CF变量socks5
 |____/ \___/ \____|_|\_\____/____/               

\e[0m"

# 获取当前用户名
USER=$(whoami)
FILE_PATH="/home/${USER}/.s5"
SOCKS5_PORT=$(curl -s https://serv00socks5.yxyfffass.workers.dev/getport | jq -r '.port')
echo "SOCKS5_PORT: ${SOCKS5_PORT}"
###################################################

socks5_config(){
# config.js文件
  cat > ${FILE_PATH}/config.json << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": $SOCKS5_PORT,
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "noauth",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF
}

install_socks5(){
  socks5_config
  if [ ! -e "${FILE_PATH}/s5" ]; then
    curl -L -sS -o "${FILE_PATH}/s5" "https://serv00socks5.yxyfffass.workers.dev/getweb"
  else
    read -p "socks5 程序已存在，是否重新下载覆盖？(Y/N 回车N)" downsocks5
    downsocks5=${downsocks5^^} # 转换为大写
    if [ "$downsocks5" == "Y" ]; then
      curl -L -sS -o "${FILE_PATH}/s5" "https://serv00socks5.yxyfffass.workers.dev/getweb"
    else
      echo "使用已存在的 socks5 程序"
    fi
  fi

  if [ -e "${FILE_PATH}/s5" ]; then
    chmod 777 "${FILE_PATH}/s5"
    nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
	  sleep 2
    pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
    CURL_OUTPUT=$(curl -s ip.sb --socks5 localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "代理创建成功，返回的IP是: $CURL_OUTPUT"
      echo "socks://${CURL_OUTPUT}:${SOCKS5_PORT}"
    else
      echo "代理创建失败，请检查自己输入的内容。"
    fi
  fi
}

########################梦开始的地方###########################

read -p "是否安装 socks5 (Y/N 回车N): " socks5choice
socks5choice=${socks5choice^^} # 转换为大写
if [ "$socks5choice" == "Y" ]; then
  # 检查socks5目录是否存在
  if [ -d "$FILE_PATH" ]; then
    install_socks5
  else
    # 创建socks5目录
    echo "正在创建 socks5 目录..."
    mkdir -p "$FILE_PATH"
    install_socks5
  fi
else
  echo "不安装 socks5"
fi

read -p "是否添加 crontab 守护进程的计划任务(Y/N 回车N): " crontabgogogo
crontabgogogo=${crontabgogogo^^} # 转换为大写
if [ "$crontabgogogo" == "Y" ]; then
  echo "添加 crontab 守护进程的计划任务"
  curl -s https://raw.githubusercontent.com/yushion/am-serv00-socks5/main/check_cron.sh | bash
else
  echo "不添加 crontab 计划任务"
fi

echo "脚本执行完成。"
