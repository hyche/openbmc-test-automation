*** Setting ***
Documentation          This suite tests for Processor Collection schema version 1.5.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${processor_uri}     Systems/1/Processors
${file_json}       ./redfish_test/expected_json/ProcessorCollection.json

*** Test Cases ***

Verify Processor Collection
    [Documentation]    Test Processor collection schema.
    [Tags]             Verify_Processor_Collection

    Verify Processor Collection Node Exist
    Verify Processor Collection Node Valid

*** Keywords ***

Get Uri Node
    [Documentation]    Get to specific URI.
    [Arguments]        ${uri_suffix}

    # Description of argument:
    # uri_suffix        The URI to establish connection with (e.g. 'Systems').

    ${resp}=           Redfish Get Request  ${uri_suffix}  ${session_id}
    ...  ${auth_token}
    [Return]           ${resp}

Get From Response
    [Documentation]    Convert to JSON object from body response content.

    ${json}=          Get Uri Node  ${processor_uri}
    [Return]          ${json}

Verify Processor Collection Node Exist
    [Documentation]  Get Processor Collection node and verify resource's exist
    [Tags]  Verify_Processor Collection_Node_Exist

    ${resp}=  Get Uri Node  ${processor_uri}
    # Verify response code: Should be 200

Verify Processor Collection Node Valid
    [Documentation]  Get Processor Collection node and verify resource's values
    ...              are same as expected values
    [Tags]  Verify_Processor Collection_Node_Valid

    ${output_json}=    Get From Response
    ${expected_json}=  Parse Json From File  ${file_json}
    Dictionary Should Contain Sub Dictionary  ${expected_json}  ${output_json}

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
