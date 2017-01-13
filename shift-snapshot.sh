#!/bin/bash
VERSION="0.3"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

#============================================================
#= snapshot.sh v0.3 created by mrgr                         =
#= Please consider voting for delegate mrgr                 =
#============================================================
echo " "

if [ ! -f ../shift/app.js ]; then
  echo "Error: No shift installation detected. Exiting."
  exit 1
fi

if [ "\$USER" == "root" ]; then
  echo "Error: SHIFT should not be run be as root. Exiting."
  exit 1
fi

SHIFT_CONFIG=~/shift/config.json
HTTP_PORT=$(cat $SHIFT_CONFIG | jq '.port')
LOCALHOST="127.0.0.1:$HTTP_PORT"
HEIGHT="0"
LOCAL_HEIGHT="0"
SYNC="0"
DB_NAME="$(grep "database" $SHIFT_CONFIG | cut -f 4 -d '"')"
DB_USER="$(grep "user" $SHIFT_CONFIG | cut -f 4 -d '"')"
DB_PASS="$(grep "password" $SHIFT_CONFIG | cut -f 4 -d '"' | head -1)"
SNAPSHOT_COUNTER=snapshot/counter.json
SNAPSHOT_LOG=snapshot/snapshot.log
if [ ! -f "snapshot/counter.json" ]; then
  mkdir -p snapshot
  sudo chmod a+x shift-snapshot.sh
  echo "0" > $SNAPSHOT_COUNTER
  sudo chown postgres:${USER:=$(/usr/bin/id -run)} snapshot
  sudo chmod -R 777 snapshot
fi
SNAPSHOT_DIRECTORY=snapshot/


NOW=$(date +"%d-%m-%Y - %T")
################################################################################
localhost_check(){
           STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
           if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
             if [ "$STATUS" -eq "200" ]; then
                LOCAL_HEIGHT=$(curl -s http://$LOCALHOST/api/loader/status/sync | jq '.height')
                SYNC=$(curl -s http://$LOCALHOST/api/loader/status/sync | jq '.syncing')
                top_height
             fi
           else
              echo "ERROR : Your localhost is not responding" | tee -a $SNAPSHOT_LOG
		LOCAL_HEIGHT="0"
           fi
}

top_height(){
        ## Get height of your 100 peers and save the highest value
        HEIGHT=$(curl -s http://$LOCALHOST/api/peers | jq '.peers[].height' | sort -nu | tail -n1)
        if ! [[ "$HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$SERVER_NAME is off?" | tee -a $SNAPSHOT_LOG
                HEIGHT="0"
            fi
}

sync_status(){
        while true; do
                check1=`curl -k -s "http://$LOCALHOST/api/loader/status/sync"| jq '.height'`
                sleep 10

                if ! [[ "$check1" =~ ^[0-9]+$ ]]; then
                    check1="0"
                fi
                top_height
                check_top=$(( $HEIGHT - 3 ))
                if [ "$check1" -lt "$check_top" ]
                then
                   pending=$(( $check_top - $check1 ))
                   echo "$check1 ---> $HEIGHT still syncing... pending $pending"
                else
                   echo "$check1 - TOP HEIGHT $HEIGHT"
                   echo "Sync process finished.."
                   break
                fi
        done
}



create_snapshot() {
  localhost_check
  if [ "$LOCAL_HEIGHT" -eq "0" ]; then
	echo "X Failed to create snapshot. Your localhost is not responding." | tee -a $SNAPSHOT_LOG
	exit 1
  else
     if [ "$SYNC" = "true" ]; then
        echo "Blockchain syncing, wait until the blockchain is synced.." | tee -a $SNAPSHOT_LOG
        sync_status
	SYNC="0"
     fi
  fi

  NOW=$(date +"%d-%m-%Y - %T")
  export PGPASSWORD=$DB_PASS
  echo " + Creating snapshot"
  echo "--------------------------------------------------"
  echo "..."
  sudo su postgres -c "pg_dump -Ft $DB_NAME > $SNAPSHOT_DIRECTORY'shift_db_snapshot.tar'"
  dbSize=`psql -d $DB_NAME -U $DB_USER -h localhost -p 5432 -t -c "select pg_size_pretty(pg_database_size('$DB_NAME'));"`

  if [ $? != 0 ]; then
    echo "$NOW -- X Failed to create snapshot." | tee -a $SNAPSHOT_LOG
    exit 1
  else
    echo "$NOW -- √ New snapshot created successfully at block $LOCAL_HEIGHT ($dbSize)." | tee -a $SNAPSHOT_LOG
  fi

}

restore_snapshot(){
  echo " + Restoring snapshot"
  echo "--------------------------------------------------"
  SNAPSHOT_FILE=`ls -t snapshot/shift_db* | head  -1`
  if [ -z "$SNAPSHOT_FILE" ]; then
    echo "$NOW -- X No snapshot to restore, please consider create it first" | tee -a $SNAPSHOT_LOG
    echo " "
    exit 1
  fi
  echo "Snapshot to restore = $SNAPSHOT_FILE"

#snapshot restoring..
  export PGPASSWORD=$DB_PASS
  pg_restore -d $DB_NAME "$SNAPSHOT_FILE" -U $DB_USER -h localhost -c -n public

  if [ $? != 0 ]; then
    echo "$NOW -- X Failed to restore." | tee -a $SNAPSHOT_LOG
    exit 1
  else
    echo "$NOW -- √ snapshot restored successfully." | tee -a $SNAPSHOT_LOG
  fi

}

show_log(){
  echo " + Snapshot Log"
  echo "--------------------------------------------------"
  cat snapshot/snapshot.log
  echo "--------------------------------------------------END"
}

schedule_cron(){
	echo "All your crontab settings will be overwritten."

        read -p "Do you want to continue (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
	echo " "
	case $1 in
	"hourly")
		echo -e "Execute: ${CYAN}sudo crontab -e${OFF} and add the following line:"
		echo "0 * * * * cd $(pwd) && bash $(pwd)/shift-snapshot.sh create >> $(pwd)/cron.log"
	;;
	"daily")
		echo -e "Execute: ${CYAN}sudo crontab -e${OFF} and add the following line:"
		echo "0 0 * * * cd $(pwd) && bash $(pwd)/shift-snapshot.sh create >> $(pwd)/cron.log" > schedule
	;;
        "weekly")
		echo -e "Execute: ${CYAN}sudo crontab -e${OFF} and add the following line:"
		echo "0 0 * * 0 cd $(pwd) && bash $(pwd)/shift-snapshot.sh create >> $(pwd)/cron.log" > schedule
        ;;
        "monthly")
		echo -e "Execute: ${CYAN}sudo crontab -e${OFF} and add the following line:"
		echo "0 0 1 * * cd $(pwd) && bash $(pwd)/shift-snapshot.sh create >> $(pwd)/cron.log" > schedule
        ;;
        *)
	echo "Error: Wrong parameter for cron option."
        ;;
	esac

	fi
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
"schedule")
  schedule_cron $2
  ;;
"hello")
  echo "Hello my friend - $NOW"
  ;;
"help")
  echo "Available commands are: "
  echo "  create   - Create new snapshot"
  echo "  restore  - Restore the last snapshot available in folder snapshot/"
  echo "  log      - Display log"
  echo "  schedule - Schedule snapshot creation periodically, available parameters:"
  echo "		- hourly"
  echo "		- daily"
  echo "		- weekly"
  echo "		- monthly"
  echo "		Example $ bash shift-snapshot.sh schedule daily"
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: create, restore, log, cron, help"
  echo "Try: bash shift-snapshot.sh help"
  ;;
esac
