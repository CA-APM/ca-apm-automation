#!/bin/bash

#
# watch perflog.txt and trigger thread dump when there is no update for 18 (<15) seconds
# should be started with e.g. nohup check_perflog.sh &
#

source ./environment.properties

declare -i perflog_update_time
declare -i current_time
declare -i seconds_since_perflog_updated
declare -i dotcount
declare -i minutecount
declare -i killcount
dotcount=0
minutecount=0

echo -n "Starting check_perflog.sh at " >> $CHECK_PERFLOG_LOG
date >> $CHECK_PERFLOG_LOG

PERFLOG="$EM_PATH/logs/perflog.txt"

if [ ! -f "$PERFLOG" ]
then
    echo "ERROR: file $PERFLOG not found, exiting ..."
    exit 1
fi

while true
do
        current_time=`date +%s`
        perflog_update_time=`date -r "${PERFLOG}" +%s`
        # echo "perflog.txt last updated at $perflog_update_time" >> $CHECK_PERFLOG_LOG
        seconds_since_perflog_updated=$current_time-$perflog_update_time
        if [ "$seconds_since_perflog_updated" -gt 18 ]
        then
                echo >> $CHECK_PERFLOG_LOG
                echo "as of "`date`" perflog.txt has not been updated in "$seconds_since_perflog_updated" seconds" >> $CHECK_PERFLOG_LOG
                dotcount=0

                if [ -f "$EM_PATH/em.pid" ]
                then
                    for i in { 1..$THREAD_DUMP_REPEAT }
                    do
                        ./$THREAD_DUMP_SCRIPT
                        sleep $THREAD_DUMP_INTERVAL
                    done
                else
                    echo "em.pid does not exist, sleep for 60 seconds" >> $CHECK_PERFLOG_LOG
                    sleep 60
                fi
        # else
            # if [ "$dotcount" -gt 9 ]
            # then
            #     dotcount=0
            #     echo " " $minutecount "minutes"
            #     minutecount=minutecount+1
            # fi
            # echo -n "." >> $CHECK_PERFLOG_LOG
            # dotcount=dotcount+1
        fi
        sleep 10
done
