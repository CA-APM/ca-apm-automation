#!/bin/sh

# use environment.properties or set EM_PATH directly
#source ./environment.properties
EM_PATH=./tmp

# are there MM for domains?
if [ -z `find ${EM_PATH}/config/modules/* -type d` ]
then
    FILES="${EM_PATH}/config/modules/*.jar"
else
    FILES="${EM_PATH}/config/modules/*.jar ${EM_PATH}/config/modules/*/*.jar"
fi

echo "Management Module jar,Management Module Name,Alert Name,Caution Action List,Danger Action List" > alert_actions.csv

echo "Examining files in $FILES:"
ls $FILES
echo
for i in $FILES
do

cp $i .
jar xvf $i ManagementModule.xml > /dev/null

mm=`echo *.jar`
# get MM name
mm_name=`echo 'cat /ManagementModule/Name' | xmllint --shell  ManagementModule.xml | tr '\n' ' ' | sed -r "s#.+<Name>(.+)</Name>.+#\1#"`

echo "Analyzing $mm_name ($mm) ..."

# line 1: xml formatting of all AlertBase elements in ManagementModule.xml
# line 2: compress to one alert per line: remove all newlines with space and '-------' with newline
# line 3: grep to filter all alerts with actions
# line 4: extract action for alert with both caution and danger alerts (optional regex did not work for me)
# line 5: extract action for alert with only caution alerts
# line 6: extract action for alert with only danger alerts
# line 7: replace action list xml with just MM/ActionName
# line 8: truncate spaces
# line 9: remove space before comma
# line 10: replace '" "' with ',' in list of actions (more than one action defined)
# line 11: remove MM name if alert and action are from the same MM

echo 'cat /ManagementModule/DataGroups/DataGroup/AlertBase' | xmllint --shell  ManagementModule.xml| \
  tr '\n' ' ' | sed 's/\-\-\-\-\-\-\-/\n/g' | \
  grep ActionID | \
  sed -r "s/^.+<Name>(.+)<\/Name>.+<CautionActionList>(.+)<\/CautionActionList>.+<DangerActionList>(.+)<\/DangerActionList>.+/\"$mm\",\"$mm_name\",\"\1\",\2,\3/g" | \
  sed -r "s/^.+<Name>(.+)<\/Name>.+<DangerActionList>(.+)<\/DangerActionList>.+/\"$mm\",\"$mm_name\",\"\1\",,\2/g" | \
  sed -r "s/^.+<Name>(.+)<\/Name>.+<CautionActionList>(.+)<\/CautionActionList>.+/\"$mm\",\"$mm_name\",\"\1\",\2,/g" | \
  sed -r 's/[[:space:]]*<ActionID>[[:space:]]*<ManagementModuleName>([^<]+)<\/ManagementModuleName>[[:space:]]*<ConstructName>([^<]+)<\/ConstructName>[[:space:]]*<\/ActionID>[[:space:]]*/\"\1\/\2\" /g' | \
  sed -r 's/[[:space:]]+/ /g' | \
  sed -r 's/[[:space:]]+,/,/g' | \
  sed -r 's/\"[[:space:]]+\"/,/g' | \
  sed -r "s/$mm_name\///g" \
  >> alert_actions.csv

rm -f ManagementModule.xml
rm -f *.jar

done
