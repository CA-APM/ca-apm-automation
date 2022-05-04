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
    echo "ERROR: cannot open directory $EM_PATH/config/modules. Make sure to change EM_PATH in environment.properties."
    exit 1
fi

if [ -z "${JAVA_HOME}" ] || [ ! -x "${JAVA_HOME}/bin/jar" ]
then
    echo "ERROR: \$JAVA_HOME is not set. Please 'export JAVA_HOME=<path to java>'."
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
    alert="no"

    while read p; do
        #echo $p

        # save Management Module name
        [[ -z $mm_name ]] && [[ $p =~ \<Name\>(.*)\</Name\> ]] && mm_name="${BASH_REMATCH[1]}"
#	&& echo "MM = '$mm_name'"

        # find start of alert definition
        [[ $p = *"<AlertBase "* ]] && container="Alert" && container_name=""

        # find start of calculator definition
        [[ $p = *"<Calculator "* ]] && container="Calculator" && container_name=""

        # find start of report element definition
        [[ $p = *"<ReportElement "* ]] && container="ReportElement" && container_name=""

        # find first container name
        [[ -n $container ]] && [[ -z $container_name ]] && [[ $p =~ \<Name.*\>(.*)\</Name\> ]] && container_name="${BASH_REMATCH[1]}"
	# && echo "found $container $container_name"

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

        # find end of calculator
        [[ $container = "Calculator" ]] && [[ $p =~ \</Calculator\> ]] && container=""

        # find end of report element
        [[ $container = "ReportElement" ]] && [[ $p =~ \</ReportElement\> ]] && container=""

        # find start of dashboard definition
        [[ $p = *"<Dashboard "* ]] && container="Dashboard" && container_name=""

        # find action
        [[ -n $container ]] && [[ $p =~ \<ActionID\> ]] && element="Action"

        # find action
        [[ -n $container ]] && [[ $p =~ \<SummaryAlertID\> ]] && element="Summary Alert"

        # find dashboard image
        [[ $container = "Dashboard" ]] && [[ $p =~ \<ImageID\> ]] && element="Image"

        # find alert
        [[ -n $container ]] && [[ $p =~ \<AlertID\> ]] && element="Alert"

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


#	if [[ -n $element_name ]]
#	then
#		if [[ "$mm_name" != "$element_mm" ]]
#		then 
#			echo "found $element ref $element_mm/'$element_name' in $container '$container_name'"
#		fi
#	fi

        # find end of dependency
        if [[ -n $container ]] && [[ -n $element ]] &&
          [[ "$p" = *"</ActionID>"* ]] || [[ "$p" = *"</ImageID>"* ]] || [[ "$p" = *"</AlertID>"* ]] ||
          [[ "$p" = *"</MetricGroupingID>"* ]] || [[ "$p" = *"</DashboardID>"* ]]
        then
            if [[ "$mm_name" != "$element_mm" ]]
            then
		((++count))
#		echo "found $element ref $element_mm/'$element_name' in $container '$container_name'"
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
