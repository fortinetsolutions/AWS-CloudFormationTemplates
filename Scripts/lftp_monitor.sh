#!/bin/bash 

#
# Variables that should be changed to match your environment
#
DIRTY_DIR=/mnt/dirty
QUARANTINE_DIR=/mnt/quarantine
LOGFILE=~/lftp/logfile
USERNAME="ftpsecure"
USERPASSWD="1hop2go"
SLEEP_PERIOD=15
TEMPDIR=/tmp

function lftp_real_run()
{
  server_ip=$1
  user=$2
  passwd=$3
  local result_file=$4
  if [ ! -e $DIRTY_DIR/ready_to_send ]
  then
    echo "==== Not ready to send ====="
    return 10
  fi
  echo "===== Ready to send, but waiting for eventual consistency ====="
  sleep 15
  while read p
  do
    echo "===== Transfer $p ====="
    lftp -u $user,$passwd $server_ip -e "put $p; bye"
    result="$?"
    echo "====== result = $? ======="
    if [ "$result" -ne 0 ]
    then 
      echo "===== Transfer $p Aborted. Moving to quarantine ====="
      filename=$(basename $p)
      aws s3 rm s3://dgclean-west/$filename
      sudo mv -f $p $QUARANTINE_DIR
    fi
    echo "===================================="
  done < $result_file
}

function lftp_dry_run()
{
  server_ip=$1
  user=$2
  passwd=$3
  dirty_dir=$4
  local result_file=$5
  tmpfile=$(mktemp /tmp/lftp_monitor.XXXXXX)
  lftp -u $user,$passwd $server_ip -e "lcd $dirty_dir;mirror -R --script=$tmpfile; bye"
  cat $tmpfile | egrep '^get -O' | sed -n -e 's/^.*file://p' > $result_file
  if [ -e $tmpfile ]
  then
      rm -f $tmpfile
  fi
  if [ -e $result_file ]
  then
    echo "===== List of files to transfer ====="
    cat $result_file
    echo "===================================="
  fi
}

usage()
{
cat << EOF
usage: $0 options

This script runs ENSO Migration Procedures

OPTIONS:
   -h      Show this message
   -c      Override Clean directory
   -q      Quarantine Directory
   -i      IP Address of FTP Server
   -l      logfile
   -s      sleep period
   -U      override default user
   -P      override default password

EOF
}



#
# Initialize these and force a command line to turn them on
#
DIRTY_DIR=/mnt/dirty
USERNAME="ftpsecure"
USERPASSWD="1hop2go"

date > $LOGFILE
echo "======= STARTING DG TRANSFER SCRIPT ======"
echo "======= STARTING DG TRANSFER SCRIPT ======" >> $LOGFILE
while getopts hd:q:i:l:s:U:P: OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             DIRTY_DIR=$OPTARG
             echo "===== DIRTY Directory $DIRTY_DIR ====" >>$LOGFILE
             ;;
         i)
             SERVER_IP=$OPTARG
             echo "===== SERVER IP: $SERVER_IP ====" >>$LOGFILE
             ;;
         l)
             LOGFILE=$OPTARG
             echo "===== LOGFILE OVERRIDE: $LOGFILE" >$LOGFILE
             ;;
         q)
             QUARANTINE_DIR=$OPTARG
             echo "===== QUARANTINE Directory $CLEAN_DIR ====" >>$LOGFILE
             ;;
         s)
             SLEEP_PERIOD=$OPTARG
             echo "===== SLEEP PERIOD $SLEEP_PERIOD ====" >>$LOGFILE
             ;;
         U)
             USERNAME=$OPTARG
             echo "===== USER = $USERNAME ====" >>$LOGFILE
             ;;
         P)
             USERPASSWD=$OPTARG
             echo "===== PASSWORD = $USERPASSWD ====" >>$LOGFILE
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

#
# See if the FTP Server is reachable... if not, wait for it.
#
logpath=$(dirname "${LOGFILE}")
echo $logpath
if [ ! -d "$logpath" ]
then
    mkdir -p $logpath
fi
waiting_for_server=true
while [[ "$waiting_for_server" == "true" ]]
do
    ping -c 3 $SERVER_IP
    if [ $? -ne 0 ]
    then
        echo "Unable to ping FTP Server" >>$LOGFILE
        sleep $SLEEP_PERIOD
        exit 1
    else
        waiting_for_server=false
    fi
done
while true
do
    result_file=$(mktemp /tmp/lftp_dry_run.XXXXXX)
    lftp_dry_run $SERVER_IP $USERNAME $USERPASSWD $DIRTY_DIR $result_file
    lftp_real_run $SERVER_IP $USERNAME $USERPASSWD $result_file
    if [ -e $result_file ]
    then
      rm -f $tmpfile
    fi
    echo "==== sleep $SLEEP_PERIOD seconds ====="
    sleep $SLEEP_PERIOD
done
