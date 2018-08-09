*** Setting ***
Documentation          This suite tests for ComputerSystem schema version 1.5.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${systems_uri}     Systems
${file_json}       ./redfish_test/expected_json/ComputerSystemCollection.json

*** Test Cases ***

Test Get Systems Node
    [Documentation]  Get systems node and verify resource's status.
    [Tags]  Test_Get_Systems_Node

    ${resp}=  Get Uri Node  ${systems_uri}
    # Verify response code: Should be 200

Test Computer System Collection
    [Documentation]    Test computer system collection schema.
    [Tags]             Test_Computer_System_Collection

    ${output_json}=    Get From Response
    ${expected_json}=  Parse Json From File  ${file_json}
    Should Be Equal  ${output_json}  ${expected_json}

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

    ${json}=          Get Uri Node  ${systems_uri}
    [Return]          ${json}

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

    FFDC On Test Case Fail
