*** Settings ***
Documentation          Test LogService System Event Log (SEL).

Library                OperatingSystem
Library                Collections
Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/state_manager.robot

Suite Setup            Suite Setup Execution
Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${SEL_uri}         Systems/1/LogServices/SEL
${log_reset_uri}   ${SEL_uri}/Actions/LogService.Reset
${expected_file_path}  ./redfish_test/expected_json/LogServiceSEL.json

*** Test Cases ***

Test Log Service SEL Get Fixed Entries
    [Documentation]  Verify response JSON with Fixed Entries
    [Tags]  Test_Log_Service_SEL_Get_Fixed_Entries

    ${expected_json}=  Parse Json From File  ${expected_file_path}
    Verify Fixed Entries Node  ${logS_info}  ${expected_json}

Test Log Service SEL Get Flexible Entries
    [Documentation]  Verify response JSON payload with Flexible Entries
    ...  from Get Method
    [Tags]  Test_Log_Service_SEL_Get_Flexible_Entries

    # Get format date-time exp: "2018-08-01T07:23:03+00:00"
    ${date}=  Get From Dictionary  ${logS_info}   DateTime
    Should Match Regexp  ${date}
    ...  ^\\d{4}\\-\\d{2}\\-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\+|\\-)\\d{2}:\\d{2}$

    ${date_local}=  Get From Dictionary  ${logS_info}   DateTimeLocalOffset
    Should Match Regexp  ${date_local}  ^(\\+|\\-)\\d{2}:\\d{2}$

    ${overW_policy}=  Get From Dictionary  ${logS_info}  OverWritePolicy
    ${overW_policy}=  Create List   ${overW_policy}
    ${expected_key}=  Get Log Collection Items Schema  OVERWRITEPOLICY
    List Should Contain Sub List  ${expected_key}   ${overW_policy}

    ${Ser_En}=  Get From Dictionary  ${logS_info}   ServiceEnabled
    Should Be Equal As Strings  ${Ser_En}  True

    ${Stt_Health}=  Get From Dictionary  ${logS_info['Status']}  Health
    ${Stt_Health}=  Create List  ${Stt_Health}
    ${expected_key}=  Get Log Collection Items Schema  HEALTH
    List Should Contain Sub List  ${expected_key}  ${Stt_Health}

    ${Stt_State}=  Get From Dictionary  ${logS_info['Status']}   State
    ${Stt_State}=  Create List  ${Stt_State}
    ${expected_key}=  Get Log Collection Items Schema   STATE
    List Should Contain Sub List  ${expected_key}   ${Stt_State}

Verify Action Log Service Reset
    [Documentation]  Verify action log service reset by post method.
    [Tags]  Verify_Action_Log_Service_Reset

    Verify Log Service Reset Post Method  Empty Data Body

    Verify Log Service Reset Post Method  Only Key Data Body

    Verify Log Service Reset Post Method  Only Value Data Body

    Verify Log Service Reset Post Method  Data Body

*** Keywords ***

Parse Json From File
    [Documentation]    Read expected JSON file then convert to JSON object.
    [Arguments]  ${json_file_path}

    # Description of argument(s):
    # json_file_path    Path of target json file

    OperatingSystem.File Should Exist  ${json_file_path}
    ${file}=          OperatingSystem.Get File  ${json_file_path}
    ${json}=          To JSON  ${file}
    [Return]          ${json}

Verify Fixed Entries Node
    [Documentation]  Verify all the fixed entries got from GET request.
    [Arguments]  ${output_req}  ${expected_json}

    Dictionary Should Contain Sub Dictionary  ${output_req}  ${expected_json}
    ...  msg=Entries not match from expected JSON
    Log  "STEP: Verify Fixed Entries Node"

Verify Log Service Reset Post Method
    [Documentation]  Verify action log service reset by POST method.
    [Arguments]  ${command}

    # Execute Log Service Reset
    :FOR  ${index}  IN RANGE  2
    \  Execute Log Service Reset  ${command}

    # Compare Remaining System Event Log
    \  ${entry}=  Redfish Get Request  ${SEL_uri}/Entries  ${session_id}
    \  ...  ${auth_token}
    \  Should Be True  ${entry["Member@odata.count"]} == 0

    # Create Event Log
    Run External IPMI Standard Command  event 1
    Run External IPMI Standard Command  event 2
    Run External IPMI Standard Command  event 3

    # Get Current Number System Event Log
    ${resp}=  Redfish Get Request  ${SEL_uri}/Entries  ${session_id}
    ...  ${auth_token}
    Should Be True  ${resp["Member@odata.count"]} == 3

    # Execute Log Service Reset
    Execute Log Service Reset  ${command}

    # Compare Remaining System Event Log
    ${entry}=  Redfish Get Request  ${SEL_uri}/Entries  ${session_id}
    ...  ${auth_token}
    Should Be True  ${entry["Member@odata.count"]} == 0

Execute Log Service Reset
    [Documentation]  Execute Log Service Reset By Post Request.
    [Arguments]  ${command}

    ${resp}=  Run Keyword If  '${command}'=='Empty Data Body'
    ...  Redfish Post Request  ${log_reset_uri}  ${auth_token}
    ...  ELSE IF  '${command}'=='Only Key Data Body'
    ...  Run Post Request  key  ${EMPTY}
    ...  ELSE IF  '${command}'=='Only Value Data Body'
    ...  Run Post Request  ${EMPTY}  value
    ...  ELSE IF  '${command}'=='Data Body'
    ...  Run Post Request  key  value
    ${status_list}=
    ...  Create List  '${HTTP_OK}'  '${HTTP_NO_CONTENT}'  '${HTTP_ACCEPTED}'
    Should Contain  ${status_list}  '${resp.status_code}'

Run Post Request
    [Documentation]  Run Post Request With Other Data Body.
    [Arguments]  ${key}  ${value}

    ${dic_value}=  Create Dictionary  ${key}=${value}
    ${resp}=  Redfish Post Request  ${log_reset_uri}  ${auth_token}
    ...  data=${dic_value}
    [Return]  ${resp}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

    ${logS_info}=  Redfish Get Request  ${SEL_uri}  ${session_id}
    ...  ${auth_token}
    Set Test Variable  ${logS_info}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}

Suite Setup Execution
    [Documentation]  Do test setup initialization.

    Initiate Host Boot
    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is Host Running

    Wait For BMC Ready
