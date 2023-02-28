# 如何恢复

您需要理解，您使用本项目时造成的数据、经济损失，本项目概不负责。

## Peek

你可以使用脚本来从备份中恢复站点。

脚本文件位于 `./scripts/restore.sh`

## 使用方法

脚本运行时需要 root 权限，因此需要使用 `sudo ./scripts/backup.sh`。
您需要在项目路径下创建一个名为 restore 的文件夹

```bash
cd wply
mkdir restore
```

接下来将备份脚本生成的备份文件放入这个文件夹中，然后运行该脚本即可。

```bash
cp site_backup/timestamp/* restore/
./scripts/restore.sh
```

## 警告

- 该脚本会删除当前的数据库文件，您的数据库会被清空，以从备份中恢复
- Docker 卷可能不会被该脚本清空，但会覆盖对应docker卷中的文件
- 数据库将短暂离线，并会重启几次
