#!/bin/sh

source ./environment.properties

# are there MM for domains?
if [ -z `find ${EM_PATH}/config/modules/* -type d` ]
then
    FILES="${EM_PATH}/config/modules/*.jar"
else
    FILES="${EM_PATH}/config/modules/*.jar ${EM_PATH}/config/modules/*/*.jar"
fi

echo "Management Module jar,Management Module Name,Alert Name,Caution Action List,Danger Action List" > alert_actions.csv

for i in $FILES
do

cp $i .
jar xvf $i ManagementModule.xml > /dev/null

mm=`echo *.jar`
# get MM name
mm_name=`echo 'cat /ManagementModule/Name' | xmllint --shell  ManagementModule.xml | tr '\n' ' ' | sed -E 's/.+\<Name\>(.+)\<\/Name\>.+/\1/' | sed -E 's#/#\\\\/#g'`

echo "Analyzing $mm_name ($mm) ..."

# line 1: xml formatting of all AlertBase elements in ManagementModule.xml
# line 2: compress to one alert per line: remove all newlines with space and '-------' with newline
# line 3: grep to filter all alerts with actions
# line 4: extract action for alert with both caution and danger alerts (optional regex did not work for me)
# line 5: extract action for alert with only caution alerts
# line 6: extract action for alert with only danger alerts
# line 7: replace action list xml with just MM/ActionName
# line 8: truncate spaces

echo 'cat /ManagementModule/DataGroups/DataGroup/AlertBase' | xmllint --shell  ManagementModule.xml| \
  tr '\n' ' ' | sed 's/\-\-\-\-\-\-\-/\n/g' | \
  grep ActionID | \
  sed -E "s/^.+\<Name\>(.+)\<\/Name\>.+\<CautionActionList\>(.+)\<\/CautionActionList\>.+\<DangerActionList\>(.+)\<\/DangerActionList\>.+/$mm,$mm_name,\1,\2,\3/g" | \
  sed -E "s/^.+\<Name\>(.+)\<\/Name\>.+\<DangerActionList\>(.+)\<\/DangerActionList\>.+/$mm,$mm_name,\1,,\2/g" | \
  sed -E "s/^.+\<Name\>(.+)\<\/Name\>.+\<CautionActionList\>(.+)\<\/CautionActionList\>.+/$mm,$mm_name,\1,\2,/g" | \
  sed -E 's/\<ActionID\>[[:space:]]*\<ManagementModuleName\>([^\<]+)\<\/ManagementModuleName\>[[:space:]]*\<ConstructName\>([^\<]+)\<\/ConstructName\>[[:space:]]*\<\/ActionID\>/ \1\/\2/g' | \
  sed -E 's/[[:space:]]+/ /g' \
  >> alert_actions.csv

rm -f ManagementModule.xml
rm -f *.jar

done