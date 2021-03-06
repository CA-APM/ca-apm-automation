#!/bin/bash

#
# check all Management Modules alert caution and danger threshold vs introscope.enterprisemanager.alerts.maxPeriods
# determine maximum period value and print all alerts exceeding property to csv file
#

source ./environment.properties


PWD=`pwd`
CSV="${PWD}/checkmm.csv"
print_all=0

while getopts ":ha" opt; do
  case ${opt} in
    h ) echo "Usage: $0 [-a]"
      exit 1
      ;;
    a ) print_all=1
      echo "printing all alerts to file $CSV"
      ;;
    \? ) echo "Usage: $0 [-a]"
      exit 1
      ;;
  esac
done

TMP_DIR=/tmp/checkmm
echo "Using $TMP_DIR to extract management modules, writing output to $CSV"
mkdir -p $TMP_DIR

if [ ! -d "$TMP_DIR" ]
then
    echo "ERROR: could not create directory $TMP_DIR"
    exit 1
fi

cd $TMP_DIR

if [ ! -d "$EM_PATH" ] || [ ! -d "$EM_PATH/config/modules" ]
then
    echo "ERROR: cannot open directory $EM_PATH/config/modules. Make sure to change \$EM_PATH in environment.properties."
    exit 1
fi

if [ -z "${JAVA_HOME}" ] || [ ! -x "${JAVA_HOME}/bin/jar" ]
then
    echo "ERROR: \$JAVA_HOME is not set. Please 'export \$JAVA_HOME=<path to java>'."
    exit 1
fi


config=`grep 'introscope.enterprisemanager.alerts.maxPeriods' $EM_PATH/config/IntroscopeEnterpriseManager.properties`

# if empty set to default
if [ -z "$config" ]
then
    config_period=20
    echo "introscope.enterprisemanager.alerts.maxPeriods=20 (default)"
else
    [[ $config =~ \=([0-9]+) ]] && config_period="${BASH_REMATCH[1]}"
    echo "introscope.enterprisemanager.alerts.maxPeriods=$config_period"
fi

# max period starting value
max_period=$config_period

# are there MM for domains?
if [ -z `find ${EM_PATH}/config/modules/* -type d` ]
then
    FILES="${EM_PATH}/config/modules/*.jar"
else
    FILES="${EM_PATH}/config/modules/*.jar ${EM_PATH}/config/modules/*/*.jar"
fi

# print csv header
echo "Management Module,Alert,CautionPeriod,DangerPeriod,CautionValue,DangerValue" > ${CSV}

for filename in $FILES
do
    echo "Opening $filename"
    "${JAVA_HOME}/bin/jar" -xf "${filename}" ManagementModule.xml
    mm_name=""
    dangerPeriod=0
    cautionPeriod=0
    alert="no"

    while read p; do
        #echo $p

        # save Management Module name
        [[ -z $mm_name ]] && [[ $p =~ \<Name\>(.*)\</Name\> ]] && mm_name="${BASH_REMATCH[1]}"

        # find start of alert definition
        [[ $p = *"<AlertBase xsi:type"* ]] && alert="yes"

        # find alert name
        [[ $alert = "yes" ]] && [[ $p =~ \<Name\>(.*)\</Name\> ]] && name="${BASH_REMATCH[1]}"

        # find caution min period
        #[[ $alert = "yes" ]] -a [[ $p =~ \<CautionMinNumPerPeriod\>(.*)\</CautionMinNumPerPeriod\> ]] && caution_min="${BASH_REMATCH[1]}"

        # find caution period
        [[ $alert = "yes" ]] && [[ $p =~ \<CautionAlertPeriod\>(.*)\</CautionAlertPeriod\> ]] && cautionPeriod="${BASH_REMATCH[1]}"

        # find danger min period
        #[[ $alert = "yes" ]] -a [[ $p =~ \<DangerMinNumPerPeriod\>(.*)\</DangerMinNumPerPeriod\> ]] && danger_min="${BASH_REMATCH[1]}"

        # find danger period
        [[ $alert = "yes" ]] && [[ $p =~ \<DangerAlertPeriod\>(.*)\</DangerAlertPeriod\> ]] && dangerPeriod="${BASH_REMATCH[1]}"

        # find danger period
        [[ $alert = "yes" ]] && [[ $p =~ \<CautionTargetValue\>(.*)\</CautionTargetValue\> ]] && cautionValue="${BASH_REMATCH[1]}"

        # find danger period
        [[ $alert = "yes" ]] && [[ $p =~ \<DangerTargetValue\>(.*)\</DangerTargetValue\> ]] && dangerValue="${BASH_REMATCH[1]}"

        # find end of alert definition
        if [[ "$alert" = "yes" ]] && [[ "$p" = *"</AlertBase>"* ]]
        then
            alert="no"
            #echo "found alert $name in MM $mm_name, cautionPeriod = $cautionPeriod, dangerPeriod = $dangerPeriod"
            if [ $print_all -o $dangerPeriod -gt $config_period -o $cautionPeriod -gt $config_period ]
            then
                # update max_period and print to csv file
                [[ $dangerPeriod -gt $max_period ]] && max_period=$dangerPeriod;
                [[ $cautionPeriod -gt $max_period ]] && max_period=$cautionPeriod;
                echo "$mm_name,$name,$cautionPeriod,$dangerPeriod,$cautionValue,$dangerValue" >> ${CSV}
            fi
        fi
    done < ${TMP_DIR}/ManagementModule.xml
    #echo "finished reading MM $mm_name"
done

# print summary
echo
if [[ $max_period -gt $config_period ]]
then
    echo "maximum alert period in all MMs = $max_period > introscope.enterprisemanager.alerts.maxPeriods = $config_period"
else
    echo "no alert found with alert period > introscope.enterprisemanager.alerts.maxPeriods = $max_period"
fi
echo

# cd back, remove tmp directory
cd ${PWD}
rm -Rf ${TMP_DIR}
