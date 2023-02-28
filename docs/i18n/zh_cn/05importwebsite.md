# 导入站点

您可以使用 `restore.sh` 恢复脚本来进行站点导入。

## 准备文件

您需要使用 `tar` 对以下目录对现有站点的文件进行压缩备份，并重命名成对应的名字分别为：

| 文件名                            | 目录                            |
| --------------------------------- | ------------------------------- |
| wply_wordpress_backup.tar.gz      | WordPress 目录                  |
| wply_phpmyadmin_backup.tar.gz     | phpMyadmin 目录                 |
| wply_lychee_config_backup.tar.gz  | lychee config 目录              |
| wply_lychee_sym_backup.tar.gz     | lychee sym 目录                 |
| wply_lychee_uploads_backup.tar.gz | lychee uploads 目录             |
| wply_certbot_cert_backup.tar.gz   | certbot 证书目录                |
| mariadb_backup.tar.gz             | mariadb backup 生成的数据库备份 |

所有文件均为可选项，如果您没有上述的目录，例如您之前没有使用 Lychee 那么您可以选择性的创建这些压缩文件。

## 数据库

您可以使用 `mariabackup` 来创建物理备份，然后使用脚本或命令行进行恢复。  
也可以使用 `mariadb-dump` 来得到逻辑备份，然后使用命令行恢复。  
如果您之前安装了 phpMyadmin ，也可以使用其来创建逻辑备份。最后，通过新站点中的 phpMyadmin 进行恢复。

## 恢复

参考 *如何恢复* 文档，运行脚本进行恢复。
