#!/bin/bash

source ./environment.properties

ssh $SSH_USER@$MOM_HOST rm $MOM_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR1_HOST rm $COLLECTOR1_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR2_HOST rm $COLLECTOR2_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR3_HOST rm $COLLECTOR3_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR4_HOST rm $COLLECTOR4_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR5_HOST rm $COLLECTOR5_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR6_HOST rm $COLLECTOR6_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR7_HOST rm $COLLECTOR7_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR8_HOST rm $COLLECTOR8_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR9_HOST rm $COLLECTOR9_PATH/logs/$THREAD_DUMP_FILE
ssh $SSH_USER@$COLLECTOR10_HOST rm $COLLECTOR10_PATH/logs/$THREAD_DUMP_FILE
