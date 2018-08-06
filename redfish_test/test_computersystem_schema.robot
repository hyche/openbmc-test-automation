*** Settings ***
Documentation          This suite tests for ComputerSystem schema version 1.5.0

Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Teardown          Test Teardown Execution

*** Test Cases ***

REDFISH Login Request
    [Documentation]  This test case do REST login request
    [Tags]  REDFISH_Login_Request

    Post Login Request  2

*** Keywords ***

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    FFDC On Test Case Fail
