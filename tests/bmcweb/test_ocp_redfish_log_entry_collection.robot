*** Settings ***
Documentation          Test Log Entry Collection schema.

Library                OperatingSystem

Resource               ../../lib/rest_client.robot
Resource               ../../lib/openbmc_ffdc.robot

Test Teardown          Test Teardown Execution

*** Variables ***

${entries_uri}         /redfish/v1/Systems/1/LogServices/SEL/Entries
${expected_file_path}  ./tests/bmcweb/expected_json/LogEntryCollection.json

*** Test Cases ***

Test Get Entries Node
    [Documentation]  Get Entries node and verify resource's status.
    [Tags]  Test_Get_Entries_Node
    [Template]  Check Response Status

    # uri               expected_status
    ${entries_uri}      ${HTTP_OK}

Test Log Entry Collection
    [Documentation]  Verify response JSON payload via expected JSON.
    [Tags]  Test_Log_Entry_Collection

    ${output_json}=    Parse Json From Response  ${entries_uri}
    ${expected_json}=  Parse Json From File  ${expected_file_path}
    Should Be Equal As Strings  ${expected_json["@odata.id"]}
    ...  ${output_json["@odata.id"]}
    # TODO  Need to verify the remained objects of Log Entry Collection shema.

*** Keywords ***

Get Request Node
    [Documentation]  Issue GET method to specific uri and return the payload.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri      The target URI to establish connection with
    #          (e.g. '/redfish/v1').

    ${resp}=          OpenBMC Get Request  ${uri}
    [Return]          ${resp}

Parse Json From Response
    [Documentation]    Convert to JSON object from body response content.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri      The target URI to establish connection with
    #          (e.g. '/redfish/v1').

    ${resp}=          Get Request Node  ${uri}
    ${json}=          To JSON  ${resp.content}
    [Return]          ${json}

Parse Json From File
    [Documentation]    Read expected JSON file then convert to JSON object.
    [Arguments]  ${json_file_path}

    # Description of argument(s):
    # json_file_path    Path of target json file

    OperatingSystem.File Should Exist  ${json_file_path}
    OperatingSystem.File Should Not Be Empty  ${json_file_path}
    ${file}=          OperatingSystem.Get File  ${json_file_path}
    ${json}=          To JSON  ${file}
    [Return]          ${json}

Check Response Status
    [Documentation]  Execute get and check reponse status from a uri.
    [Arguments]  ${uri}  ${expected_status}

    # Description of argument(s):
    # uri               The target URI to establish connection with
    #                   (e.g. '/redfish/v1').
    # expected_status   Expected response status.

    ${resp}=          Get Request Node  ${uri}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_status}

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    FFDC On Test Case Fail
