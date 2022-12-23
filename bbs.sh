#!/bin/bash
# Author: 有人说我白

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " 请以root身份执行该脚本"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update && apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
	if [[ $PMT == "apt"   ]];then
	        colorEcho $RED " 不受支持的Linux系统"
            exit 1
	fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

genDockerfile(){
cat > /tmp/xiuno/Dockerfile <<-EOF
FROM php:7.2-apache
RUN docker-php-ext-install pdo_mysql 
EOF
}

genDockerCompose(){
cat > /tmp/xiuno/docker-compose.yaml <<-EOF
version: "3.3"
services:
  xiuno:
    build: /tmp/xiuno/
    volumes:
      - /data/xiunobbs-4.0.7:/var/www/html
    ports:
      - "80:80"
    restart: always
    dns:
      - 8.8.8.8
      - 8.8.4.4
    depends_on:
      - mysql
  mysql:
    image: mysql:5.7
    volumes:
      - /data/mysql:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: xiuno4
EOF
}

preinstall() {
    #$PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    #echo $CMD_UPGRADE | bash
    echo ""
    colorEcho $BLUE " 安装必要软件"
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL epel-release
    fi
    $CMD_INSTALL docker docker-compose-1.18.0 unzip wget 
	res=`which curl 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL curl
	res=`which docker 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL docker
	systemctl enable --now docker
	res=`which docker-compose 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL docker-compose-1.18.0
	res=`which unzip 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL unzip
	res=`which wget 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL wget
	

	colorEcho $BLUE "正在下载bbs安装包..."
	wget https://ghproxy.com/https://github.com/jiix/xiunobbs/releases/download/v4.0.7/xiunobbs-v4.0.7.zip -O /tmp/xiunobbs.zip
	colorEcho $BLUE "正在创建数据目录..."
	mkdir -p /data/mysql /tmp/xiuno
	unzip /tmp/xiunobbs.zip -d /data/
	chown 33.tape -R /data/xiuno*
}

install(){
	checkSystem
	preinstall
	genDockerfile
	genDockerCompose
	docker-compose -f /tmp/xiuno/docker-compose.yaml up -d
	res=`docker-compose -f /tmp/xiuno/docker-compose.yaml ps|wc -l`
	if [[ $res == '4'  ]];then
		colorEcho $GREEN "bbs论坛安装完成！"
	else
		colorEcho $RED "bbs论坛安装失败！"
	fi
}

uninstall(){
	docker-compose -f /tmp/xiuno/docker-compose.yaml down
	rm -rf /data/mysql/
	rm -rf /data/xiunobbs-*
	colorEcho $RED "bbs论坛卸载完成！"
	
}
removeInstall(){
	rm -rf /data/xiunobbs-4.0.7/install/
	if [[ -d  /data/xiunobbs-4.0.7/install/ ]];then
		colorEcho $RED "移除install目录失败！"
	else
		colorEcho $GREEN "移除install目录成功！"
	fi
}

menu(){
menu_action=""
cat <<-EOF
-----------------------------------------
|         一键安装bbs脚本               |
|       1.安装bbs                       |
|       2.卸载bbs                       |
|       3.删除bbs的install目录          |
|       4.显示本菜单                    |
|       5.退出程序                      |
-----------------------------------------
EOF
read -p "请输入您要执行的选项[按h显示本菜单]： " menu_action
}

case_sel(){
while :
do
case $menu_action in
1)
	install
	exit
	;;
2)
	uninstall
	exit
	;;	
3)
	removeInstall
	exit
	;;
4|h)
	clear
	menu	
	;;
5|q)
	exit
	;;
*)
	echo "输入错误，我死掉了……"
	exit
	;;


esac


done

}

main(){
	menu
	case_sel
	
}

main

