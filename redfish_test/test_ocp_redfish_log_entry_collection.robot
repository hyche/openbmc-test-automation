*** Settings ***
Documentation          Test Log Entry Collection schema.

Resource               ../lib/redfish_client.robot
Library                OperatingSystem
Library                Collections
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Teardown          Test Teardown Execution

*** Variables ***

${entries_uri}         Systems/1/LogServices/SEL/Entries
${expected_file_path}  ./redfish_test/expected_json/LogEntryCollection.json

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

*** Keywords ***

Verify Fixed Entries Node
    [Documentation]  Verify all the fixed entries got from GET request.
    [Arguments]  ${output_req}  ${expected_json}

    Dictionary Should Contain Sub Dictionary  ${output_req}  ${expected_json}
    ...  msg=Entries not match from expected JSON
    Log  "STEP: Verify Fixed Entries Node"

Parse Json From Response
    [Documentation]    Convert to JSON object from body response content.
    [Arguments]  ${uri_suffix}

    # Description of argument(s):
    # uri_suffix      The target URI to establish connection with
    #                 (e.g. 'Systems').

    ${json}=          Redfish Get Request  ${uri_suffix}
    [Return]          ${json}

Check Response Status
    [Documentation]  Execute get and check reponse status from a uri.
    [Arguments]  ${uri_suffix}  ${expected_status}

    # Description of argument(s):
    # uri_suffix      The target URI to establish connection with
    #                 (e.g. 'Systems').
    # expected_status   Expected response status.

    ${resp}=          Redfish Get Request  ${uri_suffix}

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}
