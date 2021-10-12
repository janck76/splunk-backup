#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

mkdir /opt/backup /opt/backup/bin /opt/backup/log
chown -R splunk:splunk /opt/backup

cp backup_splunk.sh /opt/backup/bin
chmod 755 /opt/backup/bin/backup_splunk.sh

cp backup_splunk.{service,timer} /etc/systemd/system/

systemctl enable backup_splunk.timer
systemctl start backup_splunk.timer

