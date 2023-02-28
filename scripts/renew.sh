#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

DOCKER_COMPOSE_YML_DIR=../docker-compose.yaml

# use "certbot renew" every day/week is better
# details https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates
# https://serverfault.com/questions/790772/best-practices-for-setting-a-cron-job-for-lets-encrypt-certbot-renewal

EXITED_CONTAINERS=$(docker ps -a | grep Exited | awk '{ print $1 }')
if [ -z "$EXITED_CONTAINERS" ]; then
    echo "info: No exited containers to clean"
else
    docker rm "$EXITED_CONTAINERS"
    echo "info: Cleaned $EXITED_CONTAINERS"
fi

# renew certbot certificate
docker-compose -f $DOCKER_COMPOSE_YML_DIR run --rm certbot_renew
docker-compose -f $DOCKER_COMPOSE_YML_DIR exec nginx nginx -s reload

# add crontab
# look at your time zone to modify
# Check cert at 04:30 AM on every Monday
# 30 4 * * 1 /path/to/renew.sh
