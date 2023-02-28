# 升级

## Docker 服务

升级 docker 服务时，您可能需要使用下面这些命令：

1. 升级所有镜像： `docker-compose pull`
   - 升级单个镜像： `docker-compose pull image_name`
2. 升级所有容器： `docker-compose up -d --remove-orphans`
   - 升级单个容器： `docker-compose up -d container_name`
3. 删除旧的镜像： `docker image prune`

您应当定期重建您的容器，以接收 CVE 补丁。

### 升级 WordPress

官方提供的 WordPress 镜像能够自行管理 `/var/www/html/`，WordPress 的主题和插件被 WordPress 管理，您可以使用控制台的升级按钮对 WordPress、主题和插件进行升级。如果您想像其它容器化服务一样升级，那么您可参考相关文档对镜像进行修改。

当您需要升级 PHP 版本、接收安全补丁时则需要更新镜像。

### 升级 Lychee

建议通过更新 docker 镜像来升级 Lychee

### 升级 phpMyadmin

建议通过更新 docker 镜像来升级phpMyadmin

## Host 服务

### 升级 MariaDB

您可参照[升级文档](https://mariadb.com/docs/server/service-management/upgrades/community-server/)进行升级。

对于 Debian 来说，小版本可使用 apt 直接升级，主版本升级往往会涉及到整个系统的升级。
