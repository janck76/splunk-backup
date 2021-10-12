# splunk-backup

```
git clone https://github.com/janck76/splunk-backup.git && cd splunk-backup && sudo bash ./install.sh

systemctl list-timers|grep "NEXT\|backup_splunk"

sudo systemctl start backup_splunk

systemctl status backup_splunk

cat /opt/backup/log/splunk_backup.log
```
