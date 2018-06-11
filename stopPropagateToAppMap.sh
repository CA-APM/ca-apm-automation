#!/bin/bash

# copy script and management modules to a temporary directory and run the script.

mkdir temp
mkdir new

for i in `ls *.jar`
do
        cp $i temp
        cd temp
        jar xf $i
# change text in ManagementModule.xml for propagate from true to false
        sed -i 's/PropagateToAppMap=\"true\"/PropagateToAppMap=\"false\"/g' ManagementModule.xml
        jar cf $i *
        mv $i ../new
        rm -rf *
        cd ..
done

rmdir temp
