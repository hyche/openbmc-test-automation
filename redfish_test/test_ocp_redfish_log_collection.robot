*** Settings ***
Documentation          Test Log Entry Collection schema.

Resource               ../lib/redfish_client.robot
Library                OperatingSystem
Library                Collections
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${entries_uri}         Systems/1/LogServices/SEL/Entries
${service_uri}         Systems/1/LogServices
${expected_file_path}  ./redfish_test/expected_json/LogEntryCollection.json
${service_file_path}   ./redfish_test/expected_json/LogServiceCollection.json

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


*** Keywords ***

Verify Fixed Entries Node
    [Documentation]  Verify all the fixed entries got from GET request.
    [Arguments]  ${output_req}  ${expected_json}

    Dictionary Should Contain Sub Dictionary  ${output_req}  ${expected_json}
    ...  msg=Entries not match from expected JSON
    Log  "STEP: Verify Fixed Entries Node"

Parse Json From Response
    [Documentation]    Convert to JSON object from body response content.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri      The target URI to establish connection with
    #          (e.g. '/redfish/v1').

    ${json}=          Redfish Get Request  ${uri}  ${session_id}  ${auth_token}
    [Return]          ${json}

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
