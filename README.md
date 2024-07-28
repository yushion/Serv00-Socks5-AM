# serv00一键脚本部署socks5,可用来做CF的反代IP

这个项目的脚本会安装pm2然后用pm2管理并运行一个socks5代理,可用来做CF的反代IP


# 部署教程：

## 初始设置

1. 使用 SSH 连接到您的主机：

```
ssh <username>@<panel>.serv00.com
```

使用 serv00 通过电子邮件发送给您的信息。

2. 启用管理权限：

```
devil binexec on
```

***完成此步骤后，退出 SSH 并再次登录。***

## 开始部署

1、下载脚本(可以自己SFTP上传)
```
cd domains/<username>.serv00.net
wget https://github.com/ansoncloud8/am-serv00-socks5/raw/main/serv00_socks5.sh
```

2、给脚本赋予运行权限
```
chmod +x serv00_socks5.sh
```

3、执行脚本
```
./serv00_socks5.sh
```

4、根据脚本的提示信息进行操作
```
为了让pm2生效,中途可能需要停止脚本重连ssh，直到提示你成功安装pm2
如果出错不能继续安装了，断开ssh再重新连接，按照3的命令再重新运行脚本
```

5、设置变量,需要你输入3个变量,然后等待安装完成
```
socks5的端口
socks5的用户名
socks5的密码
```

成功运行并启动socks5代理后，脚本会提示“代理工作正常，脚本结束“

6、下载脚本进行保活(可以自己SFTP上传)
```
cd domains/<username>.serv00.net/socks5/
wget https://github.com/ansoncloud8/am-serv00-socks5/raw/main/check_socks5.sh
```

7、给脚本赋予运行权限
```
chmod +x check_socks5.sh
```

8、查看保活crontab任务
```
crontab -e
```
上面命令完会显示下面信息就是有保活设置成功
* * * * * /home/domains/<username>.serv00.net/socks5/check_socks5.sh > /dev/null 2>&1
```

## 其它说明：

1、查看代理的运行状态(在socks5.js所在目录下运行)
```
cd domains/<username>.serv00.net/socks5/
pm2 status
```

2、停止socks5代理服务
```
cd domains/<username>.serv00.net/socks5/
pm2 stop socks_proxy
```



