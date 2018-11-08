*** Setting ***
Documentation          This suite tests for memory collection schema version 1.5.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${memory_uri}     Systems/1/Memory
${file_json}      ./redfish_test/expected_json/MemoryCollection.json

*** Test Cases ***

Verify Memory Collection
    [Documentation]    Test Memory collection schema.
    [Tags]             Verify_Memory_Collection

    Verify Memory Node Exist
    Verify Memory Node Valid

*** Keywords ***

Get Uri Node
    [Documentation]    Get to specific URI.
    [Arguments]        ${uri_suffix}

    ${resp}=           Redfish Get Request  ${uri_suffix}  ${session_id}
    ...  ${auth_token}
    [Return]           ${resp}

Get From Response
    [Documentation]    Convert to JSON object from body response content.

    ${json}=          Get Uri Node  ${memory_uri}
    [Return]          ${json}

Verify Memory Node Exist
    [Documentation]  Get Memory node and verify resource is exist
    [Tags]  Verify_Memory_Node_Exist

    ${resp}=  Get Uri Node  ${memory_uri}
    # Verify response code: Should be 200

Verify Memory Node Valid
    [Documentation]  Get Memory node and verify resource's values
    ...              are same as expected values.
    [Tags]  Verify_Memory_Node_Valid

    ${output_json}=   Get From Response
    ${expected_json}=  Parse Json From File  ${file_json}
    Should Be Equal   ${output_json}  ${expected_json}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
