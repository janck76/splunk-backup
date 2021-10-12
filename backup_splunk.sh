#!/usr/bin/bash

LOGDIR="/opt/backup/log"

function now() {
   date +%F' '%T
}

function log() {
   LOG="$LOGDIR/splunk_backup.log"
   LEVEL=$1; shift
   echo "Timestamp=\"$(now)\" Level=\"$LEVEL\" Message=\"$*\"" >>$LOG
}

git_ignore() {
  cat <<EOF
etc/apps/AO/lookups/errors_triggered.csv
etc/apps/AO/lookups/errors_triggeredTmp.csv
etc/users/**/history
etc/users/**/metadata/local.meta
EOF
}

if [ ! -d $LOGDIR ]; then
  mkdir -p $LOGDIR || exit 1
fi

SPLUNK_VER=$(cat /opt/splunk/etc/splunk.version|grep VERSION=|sed 's/VERSION=//')
log "INFO" "Starting Splunk backup"

if [ -z "$SPLUNK_VER" ]; then
  log "ERROR" "Failed to get Splunk version"
  exit 1
fi

TARGET="/opt/backup/splunk_$SPLUNK_VER"
log "INFO" "Target: $TARGET"

if [ ! -d $TARGET ]; then
  mkdir $TARGET
  if [ $? -gt 0 ]; then
    log "ERROR" "Failed to create target directory $TARGET"; exit 1
  fi
fi

cd $TARGET
if [ $? -gt 0 ]; then
  log "ERROR" "Failed to cd $TARGET"; exit 1
fi

if [ ! -d .git ]; then
   git init
  if [ $? -gt 0 ]; then
    log "ERROR" "git init inside $TARGET failed"; exit 1
  fi
fi

EMAIL=$(git config --global --get user.email)
if [ -z "$EMAIL"  ]; then
  git config --global user.email "splunk@sbanken.no"
  git config --global user.name "Splunk"
fi

log "INFO" "Backing up /opt/splunk/etc"
rsync -avzh /opt/splunk/etc $TARGET &> "$LOGDIR/rsync.out"
if [ $? -gt 0 ]; then
  ERR=$(tail -1 "$LOGDIR/rsync.out")
  if [ -z $ERR ]; then
     ERR="unknown error"
  fi 
  ERR="$ERR View complete log in source=rsync.log"
  mv "$LOGDIR/rsync.out" "$LOGDIR/rsync.log"
  log "ERROR" "rsync failed, $ERR"; exit 1
fi
log "INFO" "Succesfully backed up /opt/splunk/etc"

git_ignore >$TARGET/.gitignore
git add -A
git commit -m "Auto-commit" >/tmp/commit.tmp
COUNT=0
if ! grep 'nothing to commit' /tmp/commit.tmp; then
  COUNT=$(git log --name-status -n 1|tail  +3 |grep ^[MA]|wc -l)
fi
log "INFO" "Committed $COUNT new/modified files"