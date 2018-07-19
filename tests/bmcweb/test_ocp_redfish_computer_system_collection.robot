*** Setting ***
Documentation          This suite tests for ComputerSystem schema version 1.5.0

Library                OperatingSystem
Resource               ../../lib/rest_client.robot
Resource               ../../lib/openbmc_ffdc.robot

Test Teardown          Test Teardown Execution

*** Variables ***

${system_uri}      /redfish/v1/Systems
${file_json}       ./tests/bmcweb/expected_json/ComputerSystemCollection.json

*** Test Cases ***

Test Get Systems Node
    [Documentation]  Get systems node and verify resource's status.
    [Tags]  Test_Get_Systems_Node

    ${resp}=  Get Uri Node  ${system_uri}
    # Verify response code: Should be 200
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Test Computer System Collection
    [Documentation]    Test computer system collection schema.
    [Tags]             Test_Computer_System_Collection

    ${output_json}=    Get From Response
    ${expected_json}=  Get From File  ${file_json}
    Should Be Equal  ${output_json}  ${expected_json}

*** Keywords ***

Get Uri Node
    [Documentation]    Get to specific URI.
    [Arguments]        ${uri}

    # Description of argument:
    # uri      The URI to establish connection with
    #          (e.g. '/redfish/v1/Systems').

    ${resp}=          OpenBMC Get Request  ${uri}
    [Return]           ${resp}

Get From Response
    [Documentation]    Convert to JSON object from body response content.

    ${resp}=          Get Uri Node  ${system_uri}
    ${json}=          To JSON  ${resp.content}
    [Return]           ${json}

Get From File
    [Documentation]    Read expected JSON file the convert to JSON object.
    [Arguments]        ${json_path}

    # Description of argument:
    # json_path        The path of json file

    OperatingSystem.File Should Exist  ${json_path}
    OperatingSystem.File Should Not Be Empty  ${json_path}
    ${file}=          OperatingSystem.Get File  ${json_path}
    ${json}=          To JSON  ${file}
    [Return]           ${json}

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    FFDC On Test Case Fail

