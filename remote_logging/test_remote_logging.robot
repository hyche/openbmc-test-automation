*** Settings ***
Documentation    Remote logging test for rsyslog.

# Program arguments:
# REMOTE_LOG_SERVER_HOST    The host name or IP address of the remote
#                           logging server.
# REMOTE_LOG_SERVER_PORT    The port number for the remote logging server.
# REMOTE_USERNAME           The username for the remote logging server.
# REMOTE_PASSWORD           The password for the remote logging server.

Library          String
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/boot_utils.robot
Resource         ../lib/remote_logging_utils.robot
Library          ../lib/gen_misc.py

Suite Setup      Suite Setup Execution
Test Setup       Test Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ***

# Strings to check from journald.
${BMC_STOP_MSG}          Stopping Phosphor IPMI BT DBus Bridge
${BMC_START_MSG}         Starting Flush Journal to Persistent Storage
${BMC_BOOT_MSG}          Startup finished in
${BMC_SYSLOG_REGEX}      dropbear|vrm-control.sh
${RSYSLOG_REGEX}         start|exiting on signal 15|there are no active actions configured
${RSYSLOG_RETRY_REGEX}   suspended, next retry

*** Test Cases ***

Test BMC Hostname Service And Verify
    [Documentation]  Write to hostname interface and verify via REST and
    ...              'hostname' command.
    [Tags]  Test_BMC_Hostname_Service_And_Verify

    ${openbmc_host_name}  ${openbmc_ip}  ${openbmc_short_name}=
    ...  Get Host Name IP  host=${OPENBMC_HOST}  short_name=1

    ${host_name_dict}=  Create Dictionary  data=${openbmc_short_name}
    Write Attribute  ${NETWORK_MANAGER}config  HostName  data=${host_name_dict}
    ...  verify=${TRUE}  expected_value=${openbmc_short_name}

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  hostname

    Should Be Equal As Strings  ${hostname}  ${openbmc_short_name}
    ...  msg=The hostname interface ${openbmc_short_name} and command value ${hostname} do not match.

    # Override the suite hostname variable if this test is executed.
    Set Suite Variable  ${bmc_hostname}  ${openbmc_short_name}


Verify REST Logging On BMC Journal When Disabled
    [Documentation]  Enable REST logging and verify from journald.
    [Tags]  Verify_REST_Logging_On_BMC_Journal_When_Disabled

    ${log_dict}=  Create Dictionary  data=${False}
    Write Attribute  ${BMC_LOGGING_URI}${/}rest_api_logs  Enabled  data=${log_dict}
    ...  verify=${True}  expected_value=${False}

    # If it was enabled prior, this REST footprint will show up.
    # Takes around 5 seconds for the REST to restart service when policy is changed.
    Sleep  10s

    ${login_footprint}=  Catenate  user:root POST http://127.0.0.1:8081/login json:None 200 OK
    # Example: Just get the message part of the syslog
    # user:root POST http://127.0.0.1:8081/login json:None 200 OK
    ${cmd}=  Catenate  SEPARATOR=  --no-pager | egrep '${login_footprint}'
    ...  | awk -F': ' '{print $2}'

    Start Journal Log  filter=${cmd}
    Initialize OpenBMC
    Sleep  5s
    ${bmc_journald}=  Stop Journal Log

    Should Be Empty  ${bmc_journald}
    ...  msg=${bmc_journald} contains unexpected REST entries.


Verify REST Logging On BMC Journal When Enabled
    [Documentation]  Enable REST logging and verify from journald.
    [Tags]  Verify_REST_Logging_On_BMC_Journal_When_Enabled

    ${log_dict}=  Create Dictionary  data=${True}
    Write Attribute  ${BMC_LOGGING_URI}${/}rest_api_logs  Enabled  data=${log_dict}
    ...  verify=${True}  expected_value=${True}

    # Sep 10 14:34:35 witherspoon phosphor-gevent[1288]: 127.0.0.1 user:root
    # POST http://127.0.0.1:8081/login json:None 200 OK
    Initialize OpenBMC

    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager

    Should Contain  ${bmc_journald}  user:root POST http://127.0.0.1:8081/login json:None 200 OK
    ...  msg=${bmc_journald} doesn't contains REST entries.


Test Remote API Valid Config Combination
    [Documentation]  Verify  valid combination of address and port.
    [Tags]  Test_Remote_API_Valid_Config_Combination
    [Template]  Verify Configure Remote Logging Server
    # Forego normal test setup:
    [Setup]  No Operation

    # Address                    Port                        Expected result
    ${EMPTY}                     ${REMOTE_LOG_SERVER_PORT}   ${True}
    ${REMOTE_LOG_SERVER_HOST}    ${REMOTE_LOG_SERVER_PORT}   ${True}
    remotelog.xzy.com            ${REMOTE_LOG_SERVER_PORT}   ${True}
    ${REMOTE_LOG_SERVER_HOST}    ${0}                        ${True}


Test Remote API Invalid Config Combination
    [Documentation]  Verify invalid combination of address and port.
    [Tags]  Test_Remote_API_Invalid_Config_Combination
    [Template]  Verify Configure Remote Logging Server
    # Forego normal test setup:
    [Setup]  No Operation

    # Address                    Port                        Expected result
    ${0}                         ${REMOTE_LOG_SERVER_PORT}   ${False}
    "0"                          ${REMOTE_LOG_SERVER_PORT}   ${False}
    ${REMOTE_LOG_SERVER_HOST}    ${EMPTY}                    ${False}
    ${REMOTE_LOG_SERVER_HOST}    "0"                         ${False}


Test Remote Logging REST Interface And Verify Config
    [Documentation]  Test remote logging interface and configuration.
    [Tags]  Test_Remote_Logging_REST_Interface_And_Verify_Config

    Verify Rsyslog Config On BMC

    Configure Remote Log Server With Parameters  remote_host=${EMPTY}  remote_port=0
    Verify Rsyslog Config On BMC  remote_host=remote-host  remote_port=port


Test Remote Logging Invalid Port Config And Verify BMC Journald
    [Documentation]  Test remote logging interface and configuration.
    [Tags]  Test_Remote_Logging_Invalid_Port_Config_And_Verify_BMC_Journald

    # Invalid port derived by (REMOTE_LOG_SERVER_PORT + 1) port config setting.
    ${INVALID_PORT}=  Evaluate  ${REMOTE_LOG_SERVER_PORT} + ${1}
    Configure Remote Log Server With Parameters
    ...  remote_host=${REMOTE_LOG_SERVER_HOST}  remote_port=${INVALID_PORT}

    Sleep  3s
    # rsyslogd[1870]: action 'action 0' suspended, next retry is
    # Fri Sep 14 05:47:39 2018 [v8.29.0 try http://www.rsyslog.com/e/2007 ]
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -b --no-pager | egrep 'rsyslog.*${RSYSLOG_RETRY_REGEX}'

    Should Contain  ${bmc_journald}  ${RSYSLOG_RETRY_REGEX}
    ...  msg=${bmc_journald} doesn't contain rsyslog retry entries.


Verify Rsyslog Does Not Log On BMC
    [Documentation]  Check that rsyslog journald doesn't log on BMC.
    [Tags]  Verify_Rsyslog_Does_Not_Log_On_BMC

    # Expected filter rsyslog entries.
    # Example:
    # syslogd[3356]:  [origin software="rsyslogd" swVersion="8.29.0"
    #    x-pid="3356" x-info="http://www.rsyslog.com"] exiting on signal 15.
    # rsyslogd[3364]:  [origin software="rsyslogd" swVersion="8.29.0"
    #    x-pid="3364" x-info="http://www.rsyslog.com"] start
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -b --no-pager | egrep 'rsyslog' | egrep -Ev '${RSYSLOG_REGEX}|${RSYSLOG_RETRY_REGEX}'
    ...  ignore_err=${1}

    Should Be Empty  ${bmc_journald}
    ...  msg=${bmc_journald} contains unexpected rsyslog entries.


Verfiy BMC Journald Synced To Remote Logging Server
    [Documentation]  Check that BMC journald is sync to remote rsyslog.
    [Tags]  Verfiy_BMC_Journald_Synced_To_Remote_Logging_Server

    # Restart BMC dump service and get the last entry of the journald.
    # Example:
    # systemd[1]: Started Phosphor Dump Manager.
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Dump.Manager.service

    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | grep 'Started Phosphor Dump Manager'

    # systemd[1]: Started Phosphor Dump Manager.
    ${cmd}=  Catenate  SEPARATOR=  egrep '${bmc_hostname}.*Started Phosphor Dump Manager' /var/log/syslog
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    # TODO: rsyslog configuration and time date template to match BMC journald.
    # Compare the BMC journlad log. Example:
    # systemd[1]: Started Phosphor Dump Manager.
    Should Contain  ${remote_journald}  ${bmc_journald.split('${bmc_hostname}')[1][0]}
    ...  msg= ${bmc_journald} doesn't match remote rsyslog:${remote_journald}.


Verify Journald Post BMC Reset
    [Documentation]  Check that BMC journald is sync'ed to remote rsyslog after
    ...              BMC reset.
    [Tags]  Verify_Journald_Post_BMC_Reset

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  hostname
    OBMC Reboot (off)

    ${cmd}=  Catenate  grep ${hostname} /var/log/syslog |
    ...  egrep '${BMC_STOP_MSG}|${BMC_START_MSG}|${BMC_BOOT_MSG}'
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    # 1. Last reboot message to verify.
    Should Contain  ${remote_journald}  ${BMC_STOP_MSG}
    ...  msg=The remote journald doesn't contain the IPMI shutdown message: ${BMC_STOP_MSG}.

    # 2. Earliest booting message on journald.
    Should Contain  ${remote_journald}  ${BMC_START_MSG}
    ...  msg=The remote journald doesn't contain the start message: ${BMC_START_MSG}.

    # 3. Unique boot to standby message.
    # Startup finished in 9.961s (kernel) + 1min 59.039s (userspace) = 2min 9.000s
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | egrep '${BMC_BOOT_MSG}' | tail -1

    Should Contain  ${remote_journald}
    ...  ${bmc_journald.split('${hostname}')[1]}
    ...  msg=The remote journald doesn't contain the boot message: ${BMC_BOOT_MSG}.


Verify BMC Journald Contains No Credential Data
    [Documentation]  Check that BMC journald doesn't log any credential data.
    [Tags]  Verify_BMC_Journald_Contains_No_Credential_Data

    Open Connection And Log In
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -o json-pretty | cat

    Should Not Contain Any  ${bmc_journald}  ${OPENBMC_PASSWORD}
    ...  msg=Journald logs BMC credentials/password ${OPENBMC_PASSWORD}.


Audit BMC SSH Login And Remote Logging
    [Documentation]  Check that the SSH login to BMC is logged and synced to
    ...              remote logging server.
    [Tags]  Audit_BMC_SSH_Login_And_Remote_Logging

    ${login_footprint}=  Catenate  Started SSH Per-Connection Server
    # Example: Just get the message part of the syslog
    # Started SSH Per-Connection Server (xx.xx.xx.xx:51292)
    ${cmd}=  Catenate  SEPARATOR=  --no-pager | egrep '${login_footprint}'
    ...  | awk -F': ' '{print $2}'

    Start Journal Log  filter=${cmd}
    Open Connection And Log In
    Sleep  5s
    ${bmc_journald}=  Stop Journal Log
    @{ssh_entry}=  Split To Lines  ${bmc_journald}

    ${cmd}=  Catenate  SEPARATOR=  egrep -E '*${bmc_hostname}.*${login_footprint}' /var/log/syslog

    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    Should Contain  ${remote_journald}  ${ssh_entry[0]}
    ...  msg=${remote_journald} don't contain ${bmc_journald} entry.


Boot Host And Verify Data Is Synced To Remote Server
    [Documentation]  Boot host and verify the power on sequence logs are synced
    ...              to remote logging server.
    [Tags]  Boot_Host_And_Verify_Data_Is_Synced_To_Remote_Server

    ${cmd}=  Catenate  SEPARATOR=  --no-pager | egrep -Ev '${BMC_SYSLOG_REGEX}'
    ...  | awk -F': ' '{print $2}'

    # Example: Just get the message part of the syslog
    # Started OpenPOWER OCC Active Disable.
    Start Journal Log  filter=${cmd}

    # Irrespective of the outcome, the journald should be synced.
    Run Keyword And Ignore Error  REST Power On
    ${bmc_journald}=  Stop Journal Log

    ${cmd}=  Catenate  SEPARATOR=  egrep '${bmc_hostname}' /var/log/syslog
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    @{lines}=  Split To Lines  ${bmc_journald}
    :FOR  ${line}  IN  @{lines}
    \  Log To Console  \n ${line}
    \  Should Contain  ${remote_journald}  ${line}
    ...  mgs=${line} line doesn't contain in ${remote_journald}.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${REMOTE_LOG_SERVER_HOST}
    Should Not Be Empty  ${REMOTE_LOG_SERVER_PORT}
    Should Not Be Empty  ${REMOTE_USERNAME}
    Should Not Be Empty  ${REMOTE_PASSWORD}
    Ping Host  ${REMOTE_LOG_SERVER_HOST}
    Remote Logging Server Execute Command  true
    Remote Logging Interface Should Exist

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  /bin/hostname
    Set Suite Variable  ${bmc_hostname}  ${hostname}
    Configure Remote Log Server With Parameters


Test Setup Execution
    [Documentation]  Do the test setup.

    # Retain only the past 1 second log:
    BMC Execute Command  journalctl --vacuum-time=1s

    ${config_status}=  Run Keyword And Return Status
    ...  Get Remote Log Server Configured

    Run Keyword If  ${config_status}==${FALSE}
    ...  Configure Remote Log Server With Parameters

    ${ActiveState}=  Get Service Attribute  ActiveState  rsyslog.service
    Should Be Equal  active  ${ActiveState}
    ...  msg=rsyslog logging service not in active state.


Remote Logging Interface Should Exist
    [Documentation]  Check that the remote logging URI exist.

    ${resp}=  OpenBMC Get Request  ${REMOTE_LOGGING_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Verify Configure Remote Logging Server
    [Documentation]  Configure the remote logging REST interface on BMC.
    [Arguments]  ${remote_host}  ${remote_port}  ${expectation}

    # Description of argument(s):
    # remote_host  The host name or IP address of the remote logging server
    #              (e.g. "xx.xx.xx.xx").
    # remote_port  Remote ryslog server port number (e.g. "514").
    # expectation  Expect boolean True/False.


    ${status}=  Run Keyword And Return Status
    ...  Configure Remote Log Server With Parameters  remote_host=${remote_host}  remote_port=${remote_port}

    Should Be Equal  ${status}  ${expectation}
    ...  msg=Test result ${status} and expectation ${expectation} do not match.
