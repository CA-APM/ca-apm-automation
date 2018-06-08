#!/bin/bash

#
# trigger one thread dump
# called remotely from EM Thread Dump Action
#

source ./environment.properties

# is EM running?
if [ -f "$EM_PATH/em.pid" ]
then
    EM_PID=`cat $EM_PATH/em.pid`
    #echo "kill -3 "`cat $EM_PATH/em.pid` " at " `date`
    kill -3 $EM_PID
    DATE=`date "+%Y%m%d-%H%M%S"`
    DATED_THREAD_DUMP_FILE=`echo "$THREAD_DUMP_FILE" | sed -E "s#(.*)\.([a-zA-Z]+)#\1.${DATE}.\2#"`
    if [ "$THREAD_DUMP_JSTACK" ]; then
        $THREAD_DUMP_JSTACK $EM_PID >> $DATED_THREAD_DUMP_FILE
        #echo "Jstack thread dump at " `date`
    fi
fi
