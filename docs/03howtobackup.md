# How to Backup

Please note that this project is not responsible for any data or economic losses caused by using this project.

## Peek

I have written a bash script to handle backups. Before using this script, you need to set up some information. The script can not only be used to backup a website, but also to backup all Docker volumes and all database contents.

The script file is located at `./scripts/backup.sh`.

## Usage

The script needs root permission to run, use `sudo ./scripts/backup.sh` to run.

### Parameters

After opening the script in a text editor, you can see a function called `set_env()`. You need to modify the following information:

1. `mariadb_root_password` Enter your MariaDB database root password after the `=` sign, and **do not** add spaces between the password and the equal sign.  
Note: This setting method will be optimized in the future.

The following parameter modifications are optional, and you can modify the information below according to your needs:

1. `volumes` The names of the Docker volumes to be backed up. You can use this script to back up other Docker volumes, but do not add nonexistent volumes to this array, or the script will not run.
2. `max_backups` The maximum number of backups to be kept on the server. If there are more folders in the backup directory than this number, the excess backups will be **deleted** when the script is run.
3. `timestamp` The timestamp. The backup folder will be named using the timestamp, such as `1970_01_01`.  
If you need detailed time parameters (corresponding to the scenario of generating multiple backups within one day), just uncomment the code below.
4. `backup_root` The root path of the backup folder. Do not modify this parameter if it is not necessary.
5. `backup_di`r The location of the backup folder generated during runtime. Do not modify this parameter if it is not necessary.
6. `log_dir` The log folder. Do not modify this parameter if it is not necessary.
7. `log_file` The location where the runtime log is stored. Do not modify this parameter if it is not necessary.

### Setting up Automatic Execution

First, check your system time zone, then use sudo crontab -e to set up automatic backups. You can refer to the following examples:

```bash
0 4 * * * /path/to/backup.sh # 04:00 AM on everyday
0 4 * * 1 /path/to/backup.sh # 04:00 AM on every Monday
0 4 1 * * /path/to/backup.sh # 04:00 AM on 1st day of month
```

### Backup Process

1. Stop all containers that use the volumes to be backed up.
2. Create a container and backup the volumes.
3. Backup the database.
4. Start all containers.
5. Generate the sha256 checksum.
6. Check whether the number of folders in the backup path exceeds `max_backups`.  
If there are more folders, all old folders will be deleted until the number is less than `max_backups`.

By default, backups will be generated in the `./site_backup` directory under the project path, and you can view the logs in the `./log` directory. Currently, logs are not automatically cleared.

### About Database Backup

This project uses Mariabackup for physical backup instead of logical backup. You can find the difference between them [here](https://mariadb.com/kb/en/backup-and-restore-overview/).

A physical backup will back up the entire contents of the database, and when restoring, it is also necessary to delete all contents of the target database, including database configuration information, etc.

### Improving the Script

There is a `sync_with_rsync()` function in the script that you can uncomment and improve to automatically sync backups to other servers.

### Notes

- Please do not create any files or folders under the backup path, as this may cause unexpected errors!
- Please do not imitate the script to store other files under the backup path, folders that conform to the script naming conventions will be deleted!
- The script may delete old backups when running!
