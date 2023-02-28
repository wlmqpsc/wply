# How to Deploy

## Brefore Start

### About Containerized

Not all of the service should be containerized. Like database, it may not containerized in production environment. you can found some info from [here](https://stackoverflow.com/questions/25047986/does-it-make-sense-to-dockerize-containerize-databases).

This project give you two choice:

- Full Containerized
- Semi Containerized(without databse)

At this time, full containerized is still in development, which means it **only** support auto-build, you need backup and manage data by yourself.

### Test Environment

The whole project has been tested on Debian 11 amd64. It should also work on other distributions, if you find something goes wrong, just open an issue to report.

Examples below are based on Debian.

## Prepare the Environment

You need these env to run the project.

- Docker Engine
- Docker Compose 1.28 or later
- MariaDB 10.3 or later
- MariaDB backup

MariaDB after `10.11.1` can or later can listen on more than one address. if some service on host need to use DB you can install it without set firewall.

### Install docker

To get a newer version of docker you should add the docker repo. If you installed docker before, uninstall old versions.

Read the [official docs](https://docs.docker.com/engine/install/) to get more info.

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

Set up repo

```bash
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
```

Add GPG key

```bash
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o etc/apt/keyrings/docker.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Install docker and docker compose

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Install MariaDB

You can install mariadb from Debian's official repo. You can also add the MariaDB's repo.

Read the [official docs](https://mariadb.org/documentation/#getting-started) to get more info.

```bash
sudo apt install mariadb-server mariadb-backup
sudo systemctl enable mariadb --now
```

Secure your mariadb server

```bash
sudo mariadb-secure-installation
```

### Change bind address

To enable a container to connect to a database running on the host machine, we need to ensure that the MariaDB server on the host machine is listening on a specified IP address.

By default, MariaDB listens on the IP address of the local host (localhost), which means that only the host machine itself can access the MariaDB server. To allow other devices or containers to connect to the MariaDB server, you can set the bind-address parameter in the MariaDB configuration file to the IP address of the host machine.

Here's how to configure MariaDB to listen on a specified IP address:

Edit the MariaDB configuration file. On Debian, the configuration file is located at /etc/mysql/mariadb.conf.d/50-server.cnf.

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Find and edit the bind-address parameter. Set the bind-address parameter to the IP address of the specified machine.

```ini
bind-address = 172.16.50.1
```

Save and close the file. Restart the MariaDB server to apply the changes.

```bash
sudo systemctl restart mariadb
```

Now, the MariaDB server will listen for incoming connections on the specified IP address, allowing the container to connect to the server. Note that when connecting to the MariaDB server from within a container, you will need to use this IP address of the host machine as the hostname.

### Create Users and Databases

BTW：you can use the package `pwgen` to generate passwords, for example `pwgen -s 64`.

Start and enter the MariaDB interactive environment.

```bash
sudo mariadb -u root -p
```

Now, create the wordpress and lychee users.

Each SQL statement ends with `;`. Modify the password and copy the statements line by line into the terminal. if necessary, you can change it.

You may need to write down these things:

- `'wordpress'@'%'`: `wordpress` is username
- `IDENTIFIED BY 'wordpress_password'`: change `wordpress_password` it is user's password
- CREATE DATABASE IF NOT EXISTS `wordpress`: this `wordpress` is database name

```sql
CREATE USER 'wordpress'@'172.16.50.%' IDENTIFIED BY 'wordpress_password';
GRANT USAGE ON *.* TO 'wordpress'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS `wordpress`;
GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'172.16.50.%';

CREATE USER 'lychee'@'172.16.50.%' IDENTIFIED BY 'lychee_password';
GRANT USAGE ON *.* TO 'lychee'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS `lychee`;
GRANT ALL PRIVILEGES ON `lychee`.* TO 'lychee'@'172.16.50.%';

GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.50.%' IDENTIFIED BY 'root_password' WITH GRANT OPTION;
```

## Deploy Your Site

### Clone this Project

Next, return to the main directory, install git, and use `git clone` to clone this project.

```bash
cd ~
sudo apt install git
git clone https://...
```

### Modify Files

Use the replace function to modify the following content.

- (optional) If using a containerized database, modify the password in `./mariadb/init/01.sql`
- (optional) Rename the files in `./nginx/config/*`, end with `.conf`
- In `./nginx/config/*`, replace all domain names in the nginx configuration files with your own domain name
- In `./nginx/config/phpmyadmin.example.com.nginx.conf` edit or delete `allow` `deny` to restricting access by IP address
- Choose and rename a docker-compose file, and name it to `docker-compose.yml`
- Modify the following things in the compose file:
  - `MYSQL_ROOT_PASSWORD` under phpmyadmin
  - `--email` and `--domains` under certbot
  - delete `--test-cert` not to apply staging cert under certbot
  - WordPress database info can fill on web, you can change it here or later
- Modify `./certbot/credentials.ini`
- Modify the `mariadb_root_password` in `./scripts/backup.sh`
- Modify the `DB_PASSWORD` and `TIMEZONE` in `./lychee/.env` [Reference docs](https://lycheeorg.github.io/docs/configuration.html)

Give right permissions.

```bash
chmod 755 scripts/*
chmod 600 certbot/credentials.ini
```

### Start Containers

Now, apply for an SSL certificate.

```bash
sudo docker compose run --rm certbot
```

Add Cron Jobs

```bash
sudo crontab -e
```

Look at your time zone to modify  
Example: Check cert at 04:30 AM on every Monday

```bash
30 4 * * 1 /path/to/scripts/renew.sh
```

Start the main containers.

```bash
sudo docker compose up -d
```

Now, visit your website, corresponding to the three domain names, to check if the website is running normally. If it is, then you have completed all deployment work.

## Cron Job

You need to add some cron jobs:

- Run `renew.sh` Every Week or Every Day
- Run `backup.sh`  Every Week or Every Month

for exaple:

```bash
# add crontab
# look at your time zone to modify
# Check cert at 04:30 AM on every Monday
#
# 30 4 * * 1 /path/to/renew.sh
```

## Next

look other docs to see how to import backup clone and restore your site.
