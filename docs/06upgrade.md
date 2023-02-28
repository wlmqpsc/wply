# Upgrade

## Docker Service

When upgrading the docker service, you may need to use the following commands:

1. Upgrade all images: `sudo docker compose pull`
   - Upgrade a single image: `sudo docker compose pull image_name`
2. Upgrade all containers: `sudo docker compose up -d --remove-orphans`
   - Upgrade a single container: `sudo docker compose up -d container_name`
3. Delete old images: `sudo docker image prune`

You should regularly rebuild your containers to receive CVE patches.

### Upgrade WordPress

The official WordPress image can manage `/var/www/html/` on its own. WordPress themes and plugins are managed by WordPress, and you can use the upgrade button in the console to upgrade WordPress, themes, and plugins. If you want to upgrade like other containerized services, you can refer to the relevant documentation to modify the image.

You need to update the image when you need to upgrade the PHP version or receive security patches.

### Upgrade Lychee

It is recommended to upgrade Lychee by updating the docker image.

### Upgrade phpMyadmin

It is recommended to upgrade phpMyadmin by updating the docker image.

## Host Service

### Upgrade MariaDB

You can refer to the [upgrade document](https://mariadb.com/docs/server/service-management/upgrades/community-server/) for upgrade.

For Debian, small versions can be directly upgraded using apt, and major version upgrades often involve upgrading the entire system.
