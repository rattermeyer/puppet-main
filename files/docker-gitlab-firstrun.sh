#!/bin/sh
DB_HOST=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4
if [ ! -e /etc/docker-gitlab-configured.log ]; then 
  echo docker run --name=gitlab -i -t --rm \
  -e "DB_HOST=${DB_HOST}" -e "DB_NAME=${DB_NAME}" -e "DB_USER=${DB_USER}" -e "DB_PASS=${DB_PASS}" \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:6.9.2 force=yes app:rake gitlab:setup
  touch /etc/docker-gitlab-configured.log
else
  echo "Already configured gitlab. If you want to reconfigre delete /etc/docker-gitlab-configured.log"
fi
