# easyxiuno
一键搭建xiuno论坛脚本

执行以下命令即可

```shell
bash <(curl -sL https://raw.githubusercontent.com/bhcqzf/easyxiuno/main/bbs.sh)
```


安装成功后记得再次执行脚本，删除install目录

目前支持centos，添加其他系统看需求


使用了 php:7.2-apache 作为基础镜像

安装了 pdo-mysql 拓展

源码采用 githab 上开源代码

docker-compose 编排了 2 个 docker

为了安全外部只暴露了一个 80 端口

整个项目容器化，方便使用和迁移

数据目录储存在 /data 目录下

如果需要备份，可以备份 /data 目录
