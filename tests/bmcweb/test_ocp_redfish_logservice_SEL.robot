*** Settings ***
Documentation          Test LogService System Event Log (SEL).

Library                OperatingSystem
Library                Collections
Resource               ../../lib/rest_client.robot
Resource               ../../lib/openbmc_ffdc.robot

Test Setup             Test Setup Execution

*** Variables ***

${SEL_uri}         /redfish/v1/Systems/1/LogServices/SEL
${expected_file_path}  ./tests/bmcweb/expected_json/LogServiceSEL.json

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
    ...  \\d{4}\\-\\d{2}\\-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\+|\\-)\\d{2}:\\d{2}

    ${date_local}=  Get From Dictionary  ${logS_info}   DateTimeLocalOffset
    Should Match Regexp  ${date_local}  (\\+|\\-)\\d{2}:\\d{2}

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


*** Keywords ***

Test Setup Execution
    [Documentation]  Setup and Get data from uri.

    ${resp}=  OpenBMC Get Request  ${SEL_uri}  timeout=10  quiet=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${logS_info}=  To Json  ${resp.content}
    Set Test Variable  ${logS_info}

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

