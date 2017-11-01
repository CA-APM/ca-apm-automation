#!/bin/bash

source ./environment.properties

mkdir -p $LOG_TARGET_DIR

for FILE in "${LOG_FILES[@]}"
do
    if [ -f "$EM_PATH/logs/$FILE" ]; then
        cp $FILE $LOG_TARGET_DIR/MOM-$FILE
    fi
    if [ "$COLLECTOR1_HOST" && "$COLLECTOR1_PATH" ]; then
        scp $SSH_USER@$COLLECTOR1_HOST:$COLLECTOR1_PATH/logs/$FILE $LOG_TARGET_DIR/Collector1-$FILE
    fi
    if [ "$COLLECTOR1_HOST" && "$COLLECTOR2_PATH" ]; then
        scp $SSH_USER@$COLLECTOR2_HOST:$COLLECTOR2_PATH/logs/$FILE $LOG_TARGET_DIR/Collector2-$FILE
    fi
    if [ "$COLLECTOR3_HOST" && "$COLLECTOR3_PATH" ]; then
        scp $SSH_USER@$COLLECTOR3_HOST:$COLLECTOR3_PATH/logs/$FILE $LOG_TARGET_DIR/Collector3-$FILE
    fi
    if [ "$COLLECTOR4_HOST" && "$COLLECTOR4_PATH" ]; then
        scp $SSH_USER@$COLLECTOR4_HOST:$COLLECTOR4_PATH/logs/$FILE $LOG_TARGET_DIR/Collector4-$FILE
    fi
    if [ "$COLLECTOR5_HOST" && "$COLLECTOR5_PATH" ]; then
        scp $SSH_USER@$COLLECTOR5_HOST:$COLLECTOR5_PATH/logs/$FILE $LOG_TARGET_DIR/Collector5-$FILE
    fi
    if [ "$COLLECTOR6_HOST" && "$COLLECTOR6_PATH" ]; then
        scp $SSH_USER@$COLLECTOR6_HOST:$COLLECTOR6_PATH/logs/$FILE $LOG_TARGET_DIR/Collector6-$FILE
    fi
    if [ "$COLLECTOR7_HOST" && "$COLLECTOR7_PATH" ]; then
        scp $SSH_USER@$COLLECTOR7_HOST:$COLLECTOR7_PATH/logs/$FILE $LOG_TARGET_DIR/Collector7-$FILE
    fi
    if [ "$COLLECTOR8_HOST" && "$COLLECTOR8_PATH" ]; then
        scp $SSH_USER@$COLLECTOR8_HOST:$COLLECTOR8_PATH/logs/$FILE $LOG_TARGET_DIR/Collector8-$FILE
    fi
    if [ "$COLLECTOR9_HOST" && "$COLLECTOR9_PATH" ]; then
        scp $SSH_USER@$COLLECTOR9_HOST:$COLLECTOR9_PATH/logs/$FILE $LOG_TARGET_DIR/Collector9-$FILE
    fi
    if [ "$COLLECTOR10_HOST" && "$COLLECTOR10_PATH" ]; then
        scp $SSH_USER@$COLLECTOR10_HOST:$COLLECTOR10_PATH/logs/$FILE $LOG_TARGET_DIR/Collector10-$FILE
    fi
done
