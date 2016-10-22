#!/bin/bash
VERSION="0.0.1"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "============================================================"
echo "= snapshot.sh v$VERSION created by mrgr                       ="
echo "= Please consider voting for delegate mrgr                 ="
echo "============================================================"
echo " "

if [ ! -f "$(pwd)/app.js" ]; then
  echo "Error: Please consider to execute this script on shift/ folder."
  exit 1
fi

if [ "\$USER" == "root" ]; then
  echo "Error: SHIFT should not be run be as root. Exiting."
  exit 1
fi

SNAPSHOT_COUNTER=snapshot/counter.json
SNAPSHOT_LOG=snapshot/snapshot.log
if [ ! -f "$(pwd)/snapshot/counter.json" ]; then
  mkdir -p snapshot
  echo "0" > $SNAPSHOT_COUNTER
  sudo chown postgres:${USER:=$(/usr/bin/id -run)} snapshot
  sudo chmod -R g+w snapshot
fi
SNAPSHOT_DIRECTORY=$(pwd)/snapshot/


NOW=$(date +"%d-%m-%Y - %T")
################################################################################

create_snapshot() {
  counter=$(<snapshot/counter.json)
  ((counter++))
  export PGPASSWORD="testing"
  echo " + Creating snapshot"
  echo "--------------------------------------------------"
  echo "..."
  sudo su postgres -c "pg_dump -Ft shift_db > $SNAPSHOT_DIRECTORY'shift_db$NOW.snapshot.tar'"
  blockHeight=`psql -d shift_db -U shift -h localhost -p 5432 -t -c "select height from blocks order by height desc limit 1;"`
  dbSize=`psql -d shift_db -U shift -h localhost -p 5432 -t -c "select pg_size_pretty(pg_database_size('shift_db'));"`

  if [ $? != 0 ]; then
    echo "X Failed to create snapshot."
    exit 1
  else
    echo "OK snapshot created successfully at block$blockHeight ($dbSize)."
    echo $counter > $SNAPSHOT_COUNTER
    echo "$NOW -- Snapshot created successfully at block$blockHeight ($dbSize)" >> $SNAPSHOT_LOG
  fi

}

restore_snapshot(){
  echo " + Restoring snapshot"
  echo "--------------------------------------------------"
  SNAPSHOT_FILE=`ls -t snapshot/shift_db* | head  -1`
  if [ -z "$SNAPSHOT_FILE" ]; then
    echo "****** No snapshot to restore, please consider create it first"
    echo " "
    exit 1
  fi
  echo "Snapshot to restore = $SNAPSHOT_FILE"

  read -p "Please stop node app.js first, are you ready (y/n)? " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
     echo "***** Please stop node.js first.. then execute restore again"
     echo " "
     exit 1
  fi

#snapshot restoring..
  export PGPASSWORD="testing"
  pg_restore -d shift_db "$SNAPSHOT_FILE" -U shift -h localhost -c -n public

  if [ $? != 0 ]; then
    echo "X Failed to restore."
    exit 1
  else
    echo "OK snapshot restored successfully."
  fi

}

show_log(){
  echo " + Snapshot Log"
  echo "--------------------------------------------------"
  cat snapshot/snapshot.log
  echo "--------------------------------------------------END"
}


################################################################################

case $1 in
"create")
  create_snapshot
  ;;
"restore")
  restore_snapshot
  ;;
"log")
  show_log
  ;;
"hello")
  echo "Hello my friend - $NOW"
  ;;
"help")
  echo "Available commands are: "
  echo "  create   - Create new snapshot"
  echo "  restore  - Restore the last snapshot available in folder snapshot/"
  echo "  log      - Display log"
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: create, restore, log"
  ;;
esac
