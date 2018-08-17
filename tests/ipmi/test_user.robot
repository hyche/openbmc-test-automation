*** Settings ***
Documentation       This suite is for testing user IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/bmc_network_utils.robot
Library             ../../lib/ipmi_utils.py
Variables           ../../data/ipmi_raw_cmd_table.py

Test Setup          Test Setup Execution
Test Teardown       Test Teardown Excution

*** Variables ***

${User_ID}         10
${user_name}       test10
${test_password}   abc123
${user_password}   root

*** Test Cases ***

Verify IPMI User Set Password
    [Documentation]  Verify IPMI user set password command
    [Tags]  Verify_IPMI_User_Set_Password
    [Teardown]  Test Teardown For Set Password Command

    Verify Password Setting Is Valid   ${test_password}

    Verify New Password Is Effect

*** Keywords ***

Set User Password
    [Documentation]  Setting password from other, default is password of OBMC
    [Arguments]  ${password}=${user_password}

    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set password ${User_ID} ${password}
    Set Test Variable  ${data_resp}

Verify Password Setting Is Valid
    [Documentation]  Verify the password setting is success
    [Arguments]  ${password}

    # Set new password
    Set User Password  ${password}

    # Check if command is sucess
    Should Not Contain  ${data_resp}    Invalid command
    Should Not Contain  ${data_resp}    Unspecified error

Verify New Password Is Effect
    [Documentation]  Verify the new password is effect

    # Check if new password is changed
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user test ${User_ID} 16 ${test_password}
    Should Contain  ${data_resp}  Success

Test Setup Execution
    [Documentation]  Do setup for testsuite

    # Setup env for this testsuite.
    # Create user to test with set default is enable, privilege is
    # ADMINISTRATOR, and password default is root.
    # Creat user test
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set name ${User_ID} ${user_name}

    # set Enable as default
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  user enable ${User_ID}

    # set password default
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set password ${User_ID} ${user_password}

    # set privilege for user test as ADMINISTRATOR
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user priv ${User_ID} 4 1

Test Teardown Execution
    [Documentation]  Do teardown for testsuite

    # TODO: Delete created test user.

    FFDC On Test Case Fail

Test Teardown For Set Password Command
    [Documentation]  Test Teardown For Set Password Command

    # Restore password defaul
    Set User Password
