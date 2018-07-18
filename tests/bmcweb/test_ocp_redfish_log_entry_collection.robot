*** Settings ***
Documentation          Test Log Entry Collection schema.

Library                OperatingSystem

Resource               ../../lib/rest_client.robot
Resource               ../../lib/openbmc_ffdc.robot

Test Teardown          Test Teardown Execution

*** Variables ***

${entries_uri}         /redfish/v1/Systems/1/LogServices/SEL/Entries

*** Test Cases ***

Test Get Entries Node
    [Documentation]  Get Entries node and verify resource's status.
    [Tags]  Test_Get_Entries_Node
    [Template]  Check Response Status

    # uri               expected_status
    ${entries_uri}      ${HTTP_OK}

*** Keywords ***

Get Request Node
    [Documentation]  Issue GET method to specific uri and return the payload.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri      The target URI to establish connection with
    #          (e.g. '/redfish/v1').

    ${resp}=          OpenBMC Get Request  ${uri}
    [Return]          ${resp}

Check Response Status
    [Documentation]  Execute get and check reponse status from an uri.
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
