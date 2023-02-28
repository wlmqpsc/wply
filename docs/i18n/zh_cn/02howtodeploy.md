# 如何部署

## 开始之前

### 关于容器化

并不是所有的服务都应该容器化。例如在生产环境中数据库，可能不会被容器化。你可以从[这里](https://stackoverflow.com/questions/25047986/does-it-make-sense-to-dockerize-containerize-databases)找到一些信息。

本项目提供两种选择：

- 完全容器化
- 半容器化（不包括数据库）

完全容器化仍在开发中，这意味着它**仅支持**自动搭建，你需要自己备份和管理数据。

要让容器连接到宿主机的数据库，需要确保宿主机上的 MariaDB 服务器正在监听可以被容器访问的 IP 地址。

### 测试环境

整个项目已在 Debian 11 amd64上进行了测试。应该也能在其它发行版上运行。如果你发现在运行时有错误报告，请打开一个 issue 报告问题。

以下示例基于 Debian。

## 准备环境

你需要这些环境来运行该项目。

- Docker Engine
- Docker Compose 1.28 或更高版本
- MariaDB 10.3 或更高版本
- MariaDB backup

`10.11.1` 或更高版本的MariaDB可以监听多个地址。如果主机上的某个服务需要使用数据库，可以安装它而不设置防火墙。

### 安装docker

要获得更新版本的 Docker，你应该添加 Docker 仓库。如果你之前安装过 Docker，请卸载旧版本。

阅读[官方文档](https://docs.docker.com/engine/install/)以获取更多信息。

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

设置源

```bash
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
```

添加GPG密钥

```bash
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o etc/apt/keyrings/docker.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

安装Docker和Docker Compose

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 安装MariaDB

你可以从Debian官方仓库安装Mariadb，也可以添加MariaDB的仓库。

阅读[官方文档](https://mariadb.org/documentation/#getting-started)以获取更多信息。

```bash
sudo apt install mariadb-server mariadb-backup
sudo systemctl enable mariadb --now
```

保护你的 Mariadb 服务器

```bash
sudo mariadb-secure-installation
```

### 修改监听地址

默认情况下，MariaDB 监听在本地主机（localhost）上的 IP 地址，这意味着只有宿主机本身才能访问 MariaDB 服务器。要允许其他设备或容器连接到 MariaDB 服务器，可以将 MariaDB 配置文件中的 bind-address 参数设置为宿主机的 IP 地址。

以下是如何配置 MariaDB 监听在指定的 IP 地址上：

编辑 MariaDB 配置文件。对于 Debian，配置文件位于 /etc/mysql/mariadb.conf.d/50-server.cnf。

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

找到并编辑 bind-address 参数。将 bind-address 参数设置为特定的 IP 地址。

```ini
bind-address = 172.16.50.1
```

保存并关闭文件，重启 MariaDB 服务器，以使更改生效。

```bash
sudo systemctl restart mariadb
```

现在，MariaDB 服务器将在指定的 IP 地址上监听传入连接，并允许容器连接到该服务器。注意，在容器中连接到 MariaDB 服务器时，需要使用这个特定的 IP 地址。

### 创建用户和数据库

顺便一提：你可以使用 `pwgen` 这个包来生成密码，例如 `pwgen -s 64`。

启动并进入 MariaDB 交互环境。

```bash
sudo mariadb -u root -p
```

现在，创建 wordpress 用户和 lychee 用户。

SQL 语句的一行以`;`结尾，修改用户的密码并把语句逐行复制进终端，如有需要你可以修改参数。

你可能会需要记下这些内容：

- `'wordpress'@'%'`: `wordpress` 是用户名
- `IDENTIFIED BY 'wordpress_password'`: 修改 `wordpress_password` 这是用户的密码
- CREATE DATABASE IF NOT EXISTS `wordpress`: 这里的 `wordpress` 是数据库名

```sql
CREATE USER 'wordpress'@'172.16.50.%' IDENTIFIED BY 'wordpress_password';
GRANT USAGE ON *.* TO 'wordpress'@'172.16.50.%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS `wordpress`;
GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'172.16.50.%';

CREATE USER 'lychee'@'172.16.50.%' IDENTIFIED BY 'lychee_password';
GRANT USAGE ON *.* TO 'lychee'@'172.16.50.%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS `lychee`;
GRANT ALL PRIVILEGES ON `lychee`.* TO 'lychee'@'172.16.50.%';

GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.50.%' IDENTIFIED BY 'root_password' WITH GRANT OPTION;
```

## 搭建你的站点

### 克隆本项目

接下来返回主目录，安装 git 然后使用 `git clone` 克隆本项目。

```bash
cd ~
sudo apt install git
git clone https://...
```

### 修改文件

使用替换功能修改下列内容

- （可选）使用容器化数据库的用户修改 `./mariadb/init/01.sql` 中的密码
- （可选）可以修改 `./nginx/config/*` 中的文件名，以 `.conf` 结尾
- `./nginx/config/*` 把所有 nginx 配置文件里的域名换成你的域名
- `./nginx/config/phpmyadmin.example.com.nginx.conf` 修改或删除 `allow` `deny` 来使用 ip 访问控制
- 选择并重命名一个 docker compose 文件，把它命名成 `docker-compose.yml`
- 修改 compose 文件中的下列内容
  - phpmyadmin 下的 `MYSQL_ROOT_PASSWORD`
  - certbot 下的 `--email` 和 `--domains`
  - 删除 certbot 下的 `--test-cert` 以取消申请测试证书
  - WordPress 数据库信息可以在网页中填写，你可以在这里，或在将来修改它们
- 修改 `./certbot/credentials.ini`
- 修改 `./scripts/backup.sh` 中的 `mariadb_root_password`
- 修改 `./lychee/.env` 中的 `DB_PASSWORD` 和 `TIMEZONE` [参考文档](https://lycheeorg.github.io/docs/configuration.html)

赋给文件正确的权限

```bash
chmod 755 wply/scripts/*
chmod 600 certbot/credentials.ini
```

### 启动容器

现在，申请ssl证书。

```bash
sudo docker compose run --rm certbot
```

添加定时任务

```bash
sudo crontab -e
```

修改前查看你的时区  
示例：每周一 04:30 AM 检查证书

```bash
30 4 * * 1 /path/to/scripts/renew.sh
```

启动主要的容器

```bash
sudo docker compose up -d
```

现在，访问你的网站，分别对应三个域名，检查网站运行状态。如果运行正常，那么至此，您已经完成了所有部署工作。

## Cron Job

你需要添加一些定时任务:

- 每周或每日运行 `renew.sh`
- 每周或每月运行 `backup.sh`

示例：

```bash
# add crontab
# look at your time zone to modify
# Check cert at 04:30 AM on every Monday
#
# 30 4 * * 1 /path/to/renew.sh
```

## 下一步

接下来查看其它文档来了解如何导入、备份、克隆和恢复您的站点。
