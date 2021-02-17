#!/bin/bash

#
# check all Management Modules for dependencies on other Management Modules
#

source ./environment.properties


PWD=`pwd`
CSV="${PWD}/dependencies.csv"
print_all=0
count=0

while getopts ":ha" opt; do
  case ${opt} in
    h ) echo "Usage: $0 [-a]"
      exit 1
      ;;
    a ) print_all=1
      echo "printing all dependencies to file $CSV"
      ;;
    \? ) echo "Usage: $0 [-a]"
      exit 1
      ;;
  esac
done

TMP_DIR=/tmp/dependency_mm
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

# are there MM for domains?
if [ -z `find ${EM_PATH}/config/modules/* -type d` ]
then
    FILES="${EM_PATH}/config/modules/*.jar"
else
    FILES="${EM_PATH}/config/modules/*.jar ${EM_PATH}/config/modules/*/*.jar"
fi

# print csv header
echo "Management Module,Parent Element,Name,Element Type,Management Module,Name" > ${CSV}
#echo "$mm_name,$container,$container_name,$element,$element_mm,$element_name" >> ${CSV}

for filename in $FILES
do
    echo "Opening $filename"
    "${JAVA_HOME}/bin/jar" -xf "${filename}" ManagementModule.xml
    mm_name=""
    mm_name=""
    alert="no"

    while read p; do
        #echo $p

        # save Management Module name
        [[ -z $mm_name ]] && [[ $p =~ \<Name\>(.*)\</Name\> ]] && mm_name="${BASH_REMATCH[1]}"

        # find start of alert definition
        [[ $p = *"<AlertBase "* ]] && container="Alert" && container_name=""

        # find first container name
        [[ -n $container ]] && [[ -z $container_name ]] && [[ $p =~ \<Name.*\>(.*)\</Name\> ]] && container_name="${BASH_REMATCH[1]}"

        # find management module name
        [[ -n $element ]] && [[ $p =~ \<ManagementModuleName\>(.*)\</ManagementModuleName\> ]] && element_mm="${BASH_REMATCH[1]}"

        # find construct name
        [[ -n $element ]] && [[ $p =~ \<ConstructName\>(.*)\</ConstructName\> ]] && element_name="${BASH_REMATCH[1]}"

        # find action
        [[ $container = "Alert" ]] && [[ $p =~ \<ActionID\> ]] && element="Action"

        # find alert metric grouping
        [[ -n $container ]] && [[ $p =~ \<MetricGroupingID\> ]] && element="Metric Grouping"

        # find end of alert
        [[ $container = "Alert" ]] && [[ $p =~ \</AlertBase\> ]] && container=""

        # find start of dashboard definition
        [[ $p = *"<Dashboard "* ]] && container="Dashboard" && container_name=""

        # find dashboard image
        [[ $container = "Dashboard" ]] && [[ $p =~ \<ImageID\> ]] && element="Image"

        # find dashboard alert
        [[ $container = "Dashboard" ]] && [[ $p =~ \<AlertID\> ]] && element="Alert"

        # find dashboard link
        [[ $container = "Dashboard" ]] && [[ $p =~ \<DashboardID\> ]] && element="Dashboard Link"

        # find end of dashboard
        [[ $container = "Dashboard" ]] && [[ $p =~ \</Dashboard\> ]] && container=""

        # find start of DifferentialControl definition
        [[ $p = *"<DifferentialControl"* ]] && container="DifferentialControl" && container_name=""

        # find end of dashboard
        [[ $container = "DifferentialControl" ]] && [[ $p =~ \</DifferentialControl\> ]] && container=""

        # find start of DifferentialControl definition
        [[ $p = *"<SmartReportTemplate"* ]] && container="SmartReportTemplate" && container_name=""

        # find end of dashboard
        [[ $container = "SmartReportTemplate" ]] && [[ $p =~ \</SmartReportTemplate\> ]] && container=""

        # find end of dependency
        if [[ -n $container ]] && [[ -n $element ]] &&
          [[ "$p" = *"</ActionID>"* ]] || [[ "$p" = *"</ImageID>"* ]] || [[ "$p" = *"</AlertID>"* ]] ||
          [[ "$p" = *"</MetricGroupingID>"* ]] || [[ "$p" = *"</DashboardID>"* ]]
        then
            if [[ "$mm_name" != "$element_mm" ]]
            then
              count=$((count++))
            fi

            if [[ $print_all = "1" ]] || [[ "$mm_name" != "$element_mm" ]]
            then
              echo "$mm_name,$container,$container_name,$element,$element_mm,$element_name" >> ${CSV}
            fi

            element=""
        fi

    done < ${TMP_DIR}/ManagementModule.xml
    #echo "finished reading MM $mm_name"
done

# print summary
echo
echo "found $count management module dependencies"
echo

# cd back, remove tmp directory
cd ${PWD}
#rm -Rf ${TMP_DIR}
