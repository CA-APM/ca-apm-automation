#!/bin/bash

#
# trigger one thread dump
# called remotely from EM Thread Dump Action
#

source ./environment.properties

# is EM running?
if [ -f "$EM_PATH/em.pid" ]
then
        #echo "kill -3 "`cat $EM_PATH/em.pid` " at " `date`
        kill -3 `cat $EM_PATH/em.pid`
        if [ "$THREAD_DUMP_JSTACK" ]; then
            $THREAD_DUMP_JSTACK `cat $EM_PATH/em.pid` >> $EM_PATH/logs/$THREAD_DUMP_FILE
        fi
        #echo "Jstack thread dump at " `date`
fi
