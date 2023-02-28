#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#add crontab
#look at your time zone to modify
# examples:
# 0 4 * * * /path/to/backup.sh # 04:00 AM on everyday
# 0 4 * * 1 /path/to/backup.sh # 04:00 AM on every Monday
# 0 4 1 * * /path/to/backup.sh # 04:00 AM on first day of month

# Check if the script is being run as root
check_root() {
  if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

set_env() {
  # Get db passwd
  mariadb_root_password=supersecure

  # An array of volume names to be backed up
  volumes=(
    wply_certbot_cert
    wply_lychee_config
    wply_lychee_sym
    wply_lychee_uploads
    wply_phpmyadmin
    wply_wordpress
  )

  # Maximum number of backup folders to keep
  max_backups=3

  # Set timestamp
  timestamp=$(date +"%Y_%m_%d")
  # timestamp=$(date +"%Y_%m_%d_%H_%M")

  backup_root=$(realpath ../site_backup)

  # Define the backup directory
  backup_dir="$backup_root/$timestamp"

  # Log file location
  log_dir=$(realpath ../log)
  log_file="$log_dir/backup.log"

  # Check command
  command_check mariabackup docker

  # Create dir and log file
  if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
  fi
  if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
  fi
  if [ ! -f "$log_file" ]; then
    touch "$log_file"
  fi

  # Start logging
  write_log "INFO: -----------------------"
  write_log "INFO: Starting backup process"
  write_log "INFO: -----------------------"
  cd "$backup_dir"
}

# Stop the running containers that use the volumes to be backed up
stop_container() {
  # Create an empty array to hold container IDs
  container_ids=()

  # Check if each volume exists and exit if not
  for volume_name in "${volumes[@]}"; do
    volume_exists=$(
      docker volume inspect "$volume_name" &>/dev/null
      echo $?
    )
    if [ "$volume_exists" -ne 0 ]; then
      write_log "ERROR: Volume $volume_name does not exist!"
      exit 1
    fi
  done

  # Stop any running containers that use the volumes
  for volume_name in "${volumes[@]}"; do
    container_id=$(docker ps -q --filter volume="$volume_name")
    if [ -z "$container_id" ]; then
      echo "No container found for volume $volume_name"
      echo "May be container has been stopped, skipping."
      continue
    fi
    write_log "WARNING: Stopping container: $container_id"
    docker stop "$container_id"
    container_ids+=("$container_id")
  done

  write_log "INFO: All of Containers stopped"
}

backup_volume() {
  # Loop through the array of volume names
  for volume_name in "${volumes[@]}"; do

    # Define the backup file name
    backup_file="${volume_name}_backup.tar.gz"

    write_log "INFO: Backing up $volume_name"
    docker run --rm \
      -v "$volume_name":/"$volume_name" \
      -v "$backup_dir":/backup \
      debian:stable-slim \
      bash -c "cd / && tar -zcf /backup/$backup_file $volume_name"
  done
  write_log "INFO: Volume backup finished"
}

backup_db() {
  write_log "INFO: Backing up mariadb"
  mkdir -p "$backup_dir"/mariadb
  set +e                                                                                                                 # temporarily disable exit-on-error
  output=$(mariabackup --backup --target-dir="$backup_dir"/mariadb --user=root --password="$mariadb_root_password" 2>&1) # capture stderr
  ret=$?                                                                                                                 # save exit status of mariabackup
  set -e                                                                                                                 # re-enable exit-on-error
  if [ $ret -ne 0 ] && echo "$output" | grep -q "Access denied"; then
    write_log "ERROR: Mariadb backup failed: invalid password"
    exit 1
  fi
  if [ $ret -ne 0 ]; then
    write_log "ERROR: Mariadb backup failed"
    exit 1
  fi
  write_log "INFO: DB backup generated, create archive file"
  tar -czf mariadb_backup.tar.gz mariadb
  write_log "INFO: Archive file has been created, delete original file"
  rm -rf mariadb
  write_log "INFO: Mariadb backup complete"
}

start_container() {
  # Start the containers again
  for container_id in "${container_ids[@]}"; do
    write_log "Starting $container_id"
    docker start "$container_id"
  done
  write_log "INFO: All container were started"
}

gen_checksum() {
  # Generate a sha256sum checksum for each backup file
  write_log "INFO: Generating sha256sum checksum"
  calculate_sha256 "$backup_dir" "$backup_dir/sha256sums.txt"
  write_log "INFO: sha256sum checksum complete"
}

delete_oldbackup() {
  folder_count=$(find "$backup_root" -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9]_[0-9][0-9]_[0-9][0-9]*" | wc -l)
  if [[ $folder_count -gt $max_backups ]]; then
    write_log "INFO: Detected old backup folder"
    old_folders=$(find "$backup_root" -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9]_[0-9][0-9]_[0-9][0-9]*" -printf '%T@ %p\n' | sort -n | head -n $((folder_count - max_backups)) | cut -f2- -d" ")
    for folder in $old_folders; do
      write_log "WARNING: Delete folder: $folder"
      rm -rf "$folder"
    done
  else
    write_log "INFO: No folder deletion required"
  fi
}

the_end() {
  # End logging
  write_log "INFO: -------------------------"
  write_log "INFO: Backup process completed!"
  write_log "INFO: -------------------------"
  echo "INFO: Backup completed successfully! Check the log file for more details: $log_file"
}

#######################
#       Modules       #
#######################
command_check() {
  for cmd; do
    if ! command -v "$cmd" &>/dev/null; then
      write_log "ERROR: $cmd not installed"
      exit 1
    fi
  done
}

write_log() {
  local log_message
  local timestamp
  log_message=$1
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$timestamp: $log_message"
  echo "$timestamp: $log_message" >>"$log_file"
}

calculate_sha256() {
  local directory
  local hash_file
  directory=$1
  hash_file=$2

  for file in "$directory"/*; do
    if [ -d "$file" ]; then
      # If the file is a directory, call the function recursively on that directory
      calculate_sha256 "$file" "$hash_file"
    else
      # If the file is not a directory, calculate its SHA-256 hash and append the result to the hash file
      sha256sum "$file" >>"$hash_file"
    fi
  done
}

# sync_with_rsync() {
#   local remote_server=$1
#   local remote_dir=$2
#   local options=${3:-"-avz --delete"}

#   # Check if remote server and directory exist
#   if ! ping -c1 "$remote_server" >/dev/null 2>&1; then
#     echo "ERROR: Remote server $remote_server is not reachable"
#     return 1
#   fi

#   if ! ssh "$remote_server" 'test -d $remote_dir'; then
#     echo "ERROR: Remote directory $remote_dir does not exist"
#     return 1
#   fi

#   if ! ssh "$remote_server" 'test -w $remote_dir'; then
#     echo "ERROR: No write permission on remote directory $remote_dir"
#     return 1
#   fi

#   # synchronization
#   echo "Syncing directory $backup_root to $remote_server:$remote_dir..."

#   # Verify synchronization result
#   if rsync "$options" "$backup_root/" "$remote_server:$remote_dir/"; then
#     echo "Sync successful"
#   else
#     echo "Sync failed"
#   fi
# }

main() {
  check_root
  set_env
  stop_container
  backup_volume
  backup_db
  start_container
  gen_checksum
  delete_oldbackup
  the_end
}

main
