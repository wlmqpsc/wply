#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#!/bin/bash

# This script extracts tar files that start with "wply_" and copies the contents
# to their corresponding Docker volumes. If a volume with the same name doesn't
# exist, it will be created.

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

give_warning() {
    echo "All of data in database will LOST!"
    echo "All of data in old volume will LOST!"
    echo "I Know data will lost!(y/n)"
    read -r answer
    if [[ "$answer" != @(Y|y|YES|yes) ]]; then
        exit 0
    fi
    write_log "WARNING: Starting restore in 5 second!"
    sleep 5s
}

# Navigate to the directory containing the files
set_env() {
    compose_file=$(realpath ../docker-compose.yml)
    backup_dir=$(realpath ../restore)
    data_dir=/var/lib/mysql
    # Log file location
    log_dir=$(realpath ../log)
    log_file="$log_dir/backup.log"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
    fi
}

restore_volume() {
    cd "$backup_dir" || write_log "ERROR: backup_dir not exist" && exit 2
    # Loop through all the files that start with "wply_"
    for file in wply_*; do
        # Extract the volume name
        volume=${file%_backup.tar.gz}

        # If the volume doesn't exist, create it
        write_log "WARNING: $volume volume not found, try to use compose file to create"
        if ! docker volume inspect "$volume" &>/dev/null; then
            docker compose -f "$compose_file" create
            # docker volume create "$volume"
        fi

        # Extract the file
        write_log "INFO: Extracting $file"
        tar -xzf "$file"

        # Copy the contents to the corresponding volume
        write_log "Copy files to $file volume"
        docker run --rm \
            -v "$volume":/target \
            -v "$(pwd)":/source \
            debian:stable-slim \
            bash -c "cp -rv /source/${volume}/* /target/"

        # Remove the extracted files
        rm -rf "$volume"
    done
    write_log "volumes restore completed"
}

restore_db() {
    if [ ! -f mariadb_backup.tar.gz ]; then
        write_log "WARNING: Mariadb backup not found, skip."
        return 1
    fi
    write_log "INFO: Extracting mariadb_backup.tar.gz"
    tar -xzf mariadb_backup.tar.gz
    write_log "INFO: Prepare file and stop DB"
    mariabackup --prepare --target-dir=./mariadb
    systemctl stop mariadb.service
    write_log "INFO: Mariadb has been stopped"
    write_log "WARNING: Delete current files"
    rm -rf "${data_dir:?}/"*
    write_log "INFO: Move files"
    mariabackup --move-back --target-dir=./mariadb
    chown -R mysql:mysql "$data_dir"
    #https://dba.stackexchange.com/questions/135406/automatic-recovery-of-myisam-table
    write_log "INFO: Recover myisam-table"
    systemctl start mariadb.service
    sleep 5s
    systemctl restart mariadb.service
    write_log "INFO: Mariadb restore completed"
}

write_log() {
    local log_message
    local timestamp
    log_message=$1
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp: $log_message"
    echo "$timestamp: $log_message" >>"$log_file"
}

main() {
    check_root
    give_warning
    set_env
    restore_volume
    restore_db
}

main
