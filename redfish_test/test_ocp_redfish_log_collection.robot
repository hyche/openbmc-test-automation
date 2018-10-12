*** Settings ***
Documentation          Test Log Entry Collection schema.

Resource               ../lib/redfish_client.robot
Library                OperatingSystem
Library                Collections
Library                String
Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${entries_uri}         Systems/1/LogServices/SEL/Entries
${service_uri}         Systems/1/LogServices
${expected_file_path}  ./redfish_test/expected_json/LogEntryCollection.json
${service_file_path}   ./redfish_test/expected_json/LogServiceCollection.json
${NUM_SPECIFY}          ${1}
${specify_file_path}   ./redfish_test/expected_json/SpecifiedLogEntry.json

*** Test Cases ***

Verify Log Entry Collection Fixed Entries
    [Documentation]  Verify fixed entries with expected JSON.
    [Tags]  Verify_Log_Entry_Collection_Fixed_Entries

    ${output_json}=    Parse Json From Response  ${entries_uri}
    Set Test Variable  ${output_json}
    ${expected_json}=  Parse Json From File  ${expected_file_path}
    Verify Fixed Entries Node   ${output_json}  ${expected_json}

Verify Log Entry Collection Flexible Entries
    [Documentation]  Verify response JSON payload with non-fixed entries for Log
    ...  Entry Collection.
    [Tags]  Verify_Log_Entry_Collection_Flexible_Entries

    ${output_json}=    Parse Json From Response  ${entries_uri}

    # Get number of Member@odata.count
    ${no_mem}=  Collections.Get From Dictionary  ${output_json}
    ...  Member@odata.count

    # Get Length of "Members"
    ${count}=  Get Length   ${output_json["Members"]}

    # Compare between "Member@odata.count" with total "Members"
    Should Be Equal  ${count}  ${no_mem}

    # Check for every element of "Members" should be not equal
    :FOR  ${i}  IN RANGE  ${count}
    \  Run Keyword If  ${count} <= 1  Exit For Loop
    \  ${get_policy_id}=
    ...  Set variable  ${output_json["Members"][${i}]["@odata.id"]}
    \  ${get_policy_id_pre}=  Set variable
    ...  ${output_json["Members"][${i-1}]["@odata.id"]}
    \  Should Not Be Equal As Strings  ${get_policy_id_pre}  ${get_policy_id}

Test Log Service Collection
    [Documentation]  Verify response JSON payload both all fixed and non-fixed
    ...  for service.
    [Tags]  Test_Log_Service_Collection

    ${output_json}=    Parse Json From Response  ${service_uri}
    ${expected_json}=  Parse Json From File  ${service_file_path}

    Verify Fixed Entries Node  ${output_json}  ${expected_json}

    ${no_mem}=  Collections.Get From Dictionary  ${output_json}
    ...  Members@odata.count

    # Get Length of "Members"
    ${count}=  Get Length   ${output_json["Members"]}

    # Compare between "Members@odata.count" with total "Members"
    Should Be Equal  ${count}  ${no_mem}

    ${data_id}=  Catenate   SEPARATOR=   ${service_uri}   /SEL

    :FOR  ${i}  IN RANGE  ${count}
    \  ${get_data_id}=  Get Variable Value
    ...  ${output_json["Members"][${i}]["@odata.id"]}
    \  Exit For Loop If  '${get_data_id}' == '${data_id}'
    \  Run Keyword If  ${i} == ${count}   Fail
    ...  "Test case failed with @odata.id is not exist"

Verify Specified Log Entry
    [Documentation]  Verify response JSON payload Specify Log Entry
    ...  with argument is ${NUM_SPECIFY} as <ID> for entry test log
    [Tags]  Verify_Specified_Log_Entry
    [Setup]  Setup Specified Log Entry

    Verify Fixed Entries Node  ${output_json}  ${expected_json}

    Verify Flexible Entries Node

*** Keywords ***

Setup Specified Log Entry
    [Documentation]  Do setup for specify log entry

    Test Setup Execution
    ${value}=  Redfish Get Property  ${entries_uri}  Members  ${auth_token}
    ${length}=  Get Length  ${value}
    Run Keyword If  ${length} == 0  Create Entry Log Test
    ${s_uri}=  Get From Dictionary  @{value}[0]  @odata.id
    ${specify_uri}=  Remove String  ${s_uri}  /redfish/v1/

    Set Test Variable   ${specify_uri}
    ${output_json}=  Parse Json From Response  ${specify_uri}
    Set Test Variable  ${output_json}
    ${expected_json}=  Parse Json From File  ${specify_file_path}
    Set Test Variable  ${expected_json}

Create Entry Log Test
    [Documentation]  Create an entry log for test purpose

    # using ipmi to create event 1
    Run IPMI Standard Command   event 1
    Sleep  3s
    ${value}=  Redfish Get Property  ${entries_uri}  Members  ${auth_token}
    ${length}=  Get Length  ${value}
    Run Keyword If  ${length} == 0  Fail  msg=Cannot create entry log for test
    Set Test Variable   ${value}

Verify Fixed Entries Node
    [Documentation]  Verify all the fixed entries got from GET request.
    [Arguments]  ${output_req}  ${expected_json}

    Dictionary Should Contain Sub Dictionary  ${output_req}  ${expected_json}
    ...  msg=Entries not match from expected JSON
    Log  "STEP: Verify Fixed Entries Node"

Verify Flexible Entries Node
    [Documentation]  Verify Flexible Entries from Get method for specify
    ...  logentry with ID

    # Check message(if have) is not empty
    ${mess_info}=   Get Data From Entries   ${output_json}   Message
    Run Keyword If  '${res_logs}' == 'PASS'
    ...  Should Not Be Empty  ${mess_info}

    # Check date-time correctly format as "2018-07-17T09:32"
    ${date_time}=   Get Data From Entries  ${output_json}   Created
    Run Keyword If  '${res_logs}' == 'PASS' and '${date_time}' != '${EMPTY}'
    ...  Should Match Regexp  ${date_time}
    ...  \\d{4}\\-\\d{2}\\-\\d{2}T\\d{2}:\\d{2}

    # Check "Name" entry = "Log Entry" + ID of testcase or not?
    ${get_id}=  Get Data From Entries  ${output_json}  Id

    ${exp_name}=  Get Data From Entries  ${output_json}  Name

    ${tmp_name}=  Catenate    Log Entry  ${get_id}
    Run Keyword If  '${res_logs}' == 'PASS'
    ...  Should Be Equal As Strings  ${exp_name}  ${tmp_name}

    # Check @odata.id = "uri" of testcase (combine ID)
    ${exp_dataId}=  Get From Dictionary  ${output_json}  @odata.id
    ${tmp_dataId}=  Catenate   SEPARATOR=  /redfish/v1/${specify_uri}

    Should Be Equal As Strings   ${exp_dataId}  ${tmp_dataId}

    # Check "SensorNumber" is exist or not?
    ${SensorNumber}=  Get Data From Entries  ${output_json}   SensorNumber
    Run Keyword If  '${res_logs}' == 'PASS'
    ...  Should Not Be Equal As Strings  ${SensorNumber}  ${NONE}

    # Check Sensortype is contain in list or not?
    ${sensor_type}=  Get Data From Entries  ${output_json}   SensorType
    ${sensor_type}=   Create List   ${sensor_type}
    ${expected_key}=  Get Log Collection Items Schema  SENSORTYPE
    Run Keyword If  '${res_logs}' == 'PASS'
    ...  List Should Contain Sub List   ${expected_key}   ${sensor_type}

    # Check Entrycode is contain in list or not?
    ${entrycode}=  Get Data From Entries  ${output_json}  EntryCode
    ${entrycode}=   Create List  ${entrycode}
    ${expected_key}=  Get Log Collection Items Schema  ENTRYCODE
    Run Keyword If  '${res_logs}' == 'PASS'
    ...  List Should Contain Sub List   ${expected_key}   ${entrycode}

    # Serverity is contain in list or not?
    ${severity}=  Get Data From Entries  ${output_json}  Severity
    ${severity}=  Create List  ${severity}
    ${length}=    Get Length  ${severity}
    ${expected_key}=  Get Log Collection Items Schema  SEVERITY
    Run Keyword If  '${res_logs}' == 'PASS' and ${length} != 0
    ...  List Should Contain Sub List   ${expected_key}  ${severity}

Parse Json From Response
    [Documentation]    Convert to JSON object from body response content.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri      The target URI to establish connection with
    #          (e.g. '/redfish/v1').

    ${json}=          Redfish Get Request  ${uri}  ${session_id}  ${auth_token}
    [Return]          ${json}

Get Data From Entries
    [Documentation]  Get data from output request uri and return value.
    [Arguments]  ${output_json}  ${keyword}

    ${res_logs}  ${data}=   Run Keyword And Ignore Error
    ...  Get From Dictionary  ${output_json}   ${keyword}
    Set Test Variable  ${res_logs}
    [Return]    ${data}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
