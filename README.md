# APM Automation

# Description
Scripts to automate recurring APM tasks.

## Short Description
Scripts to automate recurring APM tasks.

## APM version
Tested with CA APM 10.5.

## Supported third party versions
n/a
## Limitations
These scripts run on Linux (and probably most Unixes and even on a Mac) but not on Windows.

## License
[Apache License 2.0](LICENSE)

# Installation Instructions

## Prerequisites
* CA APM 10.x installed, ideally - but not necessarily - in the same path on every Enterprise Manager in the cluster.
* One APM user that can execute scripts and read all files in the APM installation path.
* For taking thread dumps: Java JDK (!!!) installed to be able to take thread dumps with `jstack`. CA APM installs only a JRE.

## Dependencies
n/a

## Installation
Extract archive to bin directory of CA APM Enterprise Manager installation. Make sure all shell scripts are executable: `chmod +x *.sh`

## Configuration
The file `environment.properties` contains all the variables that need to be changed in order to run the scripts. It should be copied to every Enterprise Manager. **Do not change the scripts themselves!**

* `EM_PATH`: path to the *local* EM installation directory. Needs to be adapted for every Enterprise Manager. Default value: `/opt/CA/introscope`.
* `SSH_USER`: this is the user that the scripts will use to connect to remote Enterprise Managers from the MOM. The scripts assume that the public key is known on the remote EMs. Run `ssh_publickey.sh` to make the public key of the current user (`~/.ssh/id_rsa.pub`) known on the remote server. Default value: `wily`
* `MOM_HOST`: hostname or IP address of the MOM.
* `COLLECTOR<n>_HOST`: hostname or IP address of the collector EMs. Leave empty if you don't have that many collectors in your cluster.
* `MOM_PATH`: paths to EM installation directory on the MOM. Default value: `$EM_PATH`
* `COLLECTOR<n>_PATH`: paths to EM installation directory on the repsective collector. Default value: `$EM_PATH`
* `THREAD_DUMP_REPEAT`: how many thread dumps to take on an EM. Default value: 10
* THREAD_DUMP_INTERVAL`: pause between thread dumps in seconds. Default value: 3
* `THREAD_DUMP_FILE`: name of the file name to which the thread dump is written. Default value: `thread_dump_jstack.txt`
* `THREAD_DUMP_SCRIPT`: name of the script to execute to take a thread dump. Default value: `thread_dump.sh`
* `THREAD_DUMP_ACTION_LOG`: log file of the thread dump action (`em_thread_dump_action.sh`). Default value: `thread_dump_action.log`
* `THREAD_DUMP_JSTACK`: path to the jstack binary. Requires a Java JDK, not JRE. Default value: `$EM_PATH/jdk1.8.0_131/bin/jstack`
* `CHECK_PERFLOG_LOG`: log file of the script `check_perflog.sh`. Default value: `check_perflog.log`
* `LOG_FILES`: log files to collect from all EMs with `getlogs.sh`. Default value: `( "perflog.txt" "IntroscopeEnterpriseManager.log" "em.log" "$THREAD_DUMP_FILE" )`
* `LOG_TARGET_DIR`: target directory where `getlogs.sh` will copy all the log files to. Default value: `$EM_PATH/logs/cluster`


# Usage Instructions

## Copy the public key to a remote server

All remote scripts like `em_thread_dump_action.sh` or `getlogs.sh` rely on being able to connect to remote servers (EMs) using the public key instead of being prompted for the password.

`ssh_publickey.sh <server>` appends the public key from `~/.ssh/id_rsa.pub` to `.ssh/authorized_keys` on the remote server for the current user.

*The user must be configured as `SSH_USER` in `environment.properties`. Execute this script for all collectors!*

## Take EM thread dumps based on perflog.txt

You may want to take thread dumps of one Enterprise Manager (MOM or collector) in case the EM is stalled, e.g. when a Harvest cycle takes longer than 15s.

The `check_perflog.sh` script watches the file `perflog.txt` and takes a series of thread dumps when no line is appended to the file for more than 15 seconds. It calls `thread_dump.sh`  for every single thread dump to take.

Start the script with `nohup check_perflog.sh &` or have it running as a daemon.

## Take EM thread dumps if an alert occurs

You may want to take thread dumps of all Enterprise Managers in your cluster when a certain APM alert fires.

In CA APM workstation define a shell alert action that calls `./bin/em_thread_dump_action.sh`. See [Create a Shell Command Action](https://docops.ca.com/ca-apm/10-5/en/administrating/manage-metric-data-by-using-management-modules/create-and-configure-notification-actions-in-the-workstation#CreateandConfigureNotificationActionsintheWorkstation-CreateaShellCommandAction) in the CA APM documentation.

When the action is triggered the MOM will call the script `em_thread_dump_action.sh` which will trigger a series of thread dumps to be taken on all the configured Enterprise Managers by executing `thread_dump.sh` remotely via ssh.

## Take a single thread dump

The script `thread_dump.sh` will take a single thread dump from the process with `em.pid` using the binary jstack as configured in `environment.properties`.

## Get log files from all Enterprise Managers

`getlogs.sh` collects all the log files configured as `LOG_FILES` in `environment.properties` from the Enterprise Managers, prefixes them with `MOM-` or `Collector<n>`, respectively, and saves them in the `LOG_TARGET_DIR` directory.

The script assumes all log files are stored in the default directory `$EM_PATH/logs`. If they are stored in another location, e.g. `/var/log/` the script has to be changed accordingly.

## Remove the 'Propagate to Team Center' Flag from Alerts

Custom built CA APM Management Modules often have a lot of alerts defined for monitoring custom applications on thousands of metrics. In CA APM 10.x these alerts can mapped on to nodes (vertices) in the application map if the checkbox *Propagate to Team Center* is checked in the Management Module configuration. During an upgrade to CA APM 10.x this flag is automatically added and activated for all existing Management Modules. This can lead to a huge performance impact if you have hundred thousands of metrics mapped thousands of vertices in every 15s interval.

Therefore this script deactivates the 'Propagate to Team Center' flag in Management Modules. We suggest you run the following script on all of your custom metrics during an upgrade.

* Stop your Enterprise Manager.
* Copy `stopPropagateToAppMap.sh` to a temporary directory.
* Copy all the custom Management Modules (`*.jar` files) for which you want to deactivate 'Propagate to Team Center' from `<EM_HOME>/config/modules` to a temporary directory.
* Backup all those custom Management Modules.
* Run `./stopPropagateToAppMap.sh`
* The script will create a copy of all Management Modules in the `new` subdirectory.
* Copy the new Management Module files from the `new` directory back to `<EM_HOME>/config/modules`
* Start the Enterprise Manager.
* Check `<EM_HOME>/log/IntroscopeEnterpriseManager.properties`

## Check Alert Periods in Management Modules

In APM 10.7 SP1 a new property `introscope.enterprisemanager.alerts.maxPeriods` with a default value of 20 was introduced to reduce memory consumption. If a custom Management Modules has alerts with caution or danger "Periods Over Threshold" with "Observed Periods" greater than the value of the property `introscope.enterprisemanager.alerts.maxPeriods`, e.g. 20 out of 40, the loading of that Management Module will fail with an error message indicating the problem.

The script `check_mm.sh` checks all Management Modules in your APM installation whether they exceed that treshold. To run that script:

1. Set `EM_PATH` in `environment.properties` to point to your APM installation
2. Make sure the environment variable `JAVA_HOME` is set and the `jar` executable is available
3. Run `./check_mm.sh`.
4. The script will print what it is doing:
  1. check all Management Modules in `EM_PATH`
  2. print the maximum alert period duration encountered and
  3. write all alerts that exceed `introscope.enterprisemanager.alerts.maxPeriods` to `checkmm.csv`.
5. If you run the script with the option `-a` it will write all alerts with periods and threshold values to `checkmm.csv`.


## Check Management Modules Dependencies

Although the recommended best practice is to make Management Modules self-sufficient it is possible to re-use existing components (metric groupings, alerts, actions, dashboards) from other management modules. If you import a Management Modules with dependencies into a new APM cluster or tenant you have to import the dependency first.

The script `dependency_mm.sh` checks all Management Modules in your APM installation for dependencies. To run that script:

1. Set `EM_PATH` in `environment.properties` to point to your APM installation
2. Make sure the environment variable `JAVA_HOME` is set and the `jar` executable is available
3. Run `./dependency_mm.sh`.
4. The script will print what it is doing:
  1. check all Management Modules in `EM_PATH`
  2. write all elements that depend on another Management Module to `dependencies.csv`.
5. If you run the script with the option `-a` it will write all elements that may have dependencies to `dependencies.csv`.


## Export All Actions

The script `list_actions.sh` checks all Management Modules in your APM installation for actions and generates a csv file that contains the Management Module jar-file name and Name, Alert Name, Caution Action List and Danger Action List.

1. Set `EM_PATH` in `environment.properties` to point to your APM installation
2. Run `./list_actions.sh`.
3. The script will print what it is doing:
  1. check all Management Modules in `EM_PATH`
  2. write all actions in alerts to `alert_actions.csv`.


## Debugging and Troubleshooting
Check the log file written by the individual scripts.

## Future work
Anybody can contribute to this project over github. E.g. changing a property in a configuration file on every EM, backup/copy configuration or data files, restarting a process, ...

## Support
This document and associated tools are made available from CA Technologies as examples and provided at no charge as a courtesy to the CA APM Community at large. This resource may require modification for use in your environment. However, please note that this resource is not supported by CA Technologies, and inclusion in this site should not be construed to be an endorsement or recommendation by CA Technologies. These utilities are not covered by the CA Technologies software license agreement and there is no explicit or implied warranty from CA Technologies. They can be used and distributed freely amongst the CA APM Community, but not sold. As such, they are unsupported software, provided as is without warranty of any kind, express or implied, including but not limited to warranties of merchantability and fitness for a particular purpose. CA Technologies does not warrant that this resource will meet your requirements or that the operation of the resource will be uninterrupted or error free or that any defects will be corrected. The use of this resource implies that you understand and agree to the terms listed herein.

Although these utilities are unsupported, please let us know if you have any problems or questions by adding a comment to the CA APM Community Site area where the resource is located, so that the Author(s) may attempt to address the issue or question.

Unless explicitly stated otherwise this extension is only supported on the same platforms as the APM core agent. See [APM Compatibility Guide](http://www.ca.com/us/support/ca-support-online/product-content/status/compatibility-matrix/application-performance-management-compatibility-guide.aspx).

### Support URL
https://github.com/CA-APM/ca-apm-automation

# Contributing
The [CA APM Community](https://communities.ca.com/community/ca-apm) is the primary means of interfacing with other users and with the CA APM product team.  The [developer subcommunity](https://communities.ca.com/community/ca-apm/ca-developer-apm) is where you can learn more about building APM-based assets, find code examples, and ask questions of other developers and the CA APM product team.

If you wish to contribute to this or any other project, please refer to [easy instructions](https://communities.ca.com/docs/DOC-231150910) available on the CA APM Developer Community.

## Categories

Integration DevOps Examples


# Change log
Changes for each version of the extension.

Version | Author | Comment
--------|--------|--------
1.0 | CA Technologies | First version of the extension.
