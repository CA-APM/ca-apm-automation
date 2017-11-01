#!/bin/sh
ssh $1 mkdir -p .ssh
cat ~/.ssh/id_rsa.pub | ssh $1 'cat >> .ssh/authorized_keys'
