*** Settings ***
Documentation       This suite is for testing user IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/bmc_network_utils.robot
Library             ../../lib/ipmi_utils.py
Variables           ../../data/ipmi_raw_cmd_table.py

Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution

*** Variables ***

${user_id}         10
${user_name}       test10
${test_password}   abc123
${name_test}       Test10
${user_password}   root

*** Test Cases ***

Verify IPMI User Set Password
    [Documentation]  Verify IPMI user set password command
    [Tags]  Verify_IPMI_User_Set_Password
    [Teardown]  Test Teardown For Set Password Command

    Verify Password Setting Is Valid   ${test_password}

    Verify New Password Is Effect

Verify IMPI User Set Name Command
    [Documentation]  Verify ipmi user set name command
    [Tags]  Verify_IPMI_User_Set_Name_Command
    [Teardown]  Test Teardown For User Set Name Command

    Verify Set Name Command Valid  user set name ${user_id} ${name_test}

    Verify Set Name Command Functional

Verify IMPI User Enable Command
    [Documentation]  Verify ipmi enable command
    [Tags]  Verify_IPMI_User_Enable_Command
    [Setup]  Test Setup For User Enable Command
    [Teardown]  Test Teardown For User Enable Command

    Verify Enable Command Valid

    Verify Enable Command Functional   user list

Verify IMPI User Disable Command
    [Documentation]  Verify IPMI user disable command
    [Tags]  Verify_IPMI_User_Disable_Command
    [Setup]  Test Setup For User Disable Command
    [Teardown]  Test Teardown For User Disable Command

    Verify Disable Command Valid

    Verify Disable Command Functional   user list

Verify IMPI User Change Priv Command
    [Documentation]  Verify ipmi user change privilege
    [Tags]  Verify_IPMI_User_Change_Priv_Command
    [Teardown]  Test Teardown For User Privilege Command

    Verify Privilege Of User After Setting

*** Keywords ***

Test Setup For User Disable Command
    [Documentation]  Do test case setup for user disable command.
    Log To Console  "Test Setup For User Disable Command"
    # Set user with default status is enable
    Run Keyword And Ignore Error  Run External IPMI Standard Command
    ...  channel setaccess 1 ${user_id} link=on ipmi=on callin=on privilege=4

    Run Keyword And Ignore Error  Run External IPMI Standard Command
    ...  user enable ${user_id}

Set User Password
    [Documentation]  Setting password from other, default is password of OBMC
    [Arguments]  ${password}=${user_password}

    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set password ${user_id} ${password}
    Set Test Variable  ${data_resp}

Test Setup For User Enable Command
    [Documentation]  Do test case setup for user enable command.
    Log To Console  "Test Setup For Enable testcase"
    # Set user with default status is disable
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  channel setaccess 1 ${user_id} link=on ipmi=on callin=on privilege=4

    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user disable ${user_id}

Get Current User Privilege
    [Documentation]  Get current privilege from user priv command.

    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  user list
    ${resp}=  Get Lines Containing String  ${data_resp}  ${user_name}
    @{word}=  Split String  ${resp}
    Set Test Variable  ${priv_data}  @{word}[5]

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
    ...  user test ${user_id} 16 ${test_password}
    Should Contain  ${data_resp}  Success

Suite Setup Execution
    [Documentation]  Do setup for testsuite

    # Setup env for this testsuite.
    # Create user to test with set default is enable, privilege is
    # ADMINISTRATOR, and password default is root.
    # Creat user test
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set name ${user_id} ${user_name}

    # set Enable as default
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  user enable ${user_id}

    # set password default
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user set password ${user_id} ${user_password}

    # set privilege for user test as ADMINISTRATOR
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user priv ${user_id} 4 1

Suite Teardown Execution
    [Documentation]  Do teardown for testsuite

    # TODO: Delete created test user.

    Log To Console  "TODO: Delete created test user"

Verify Set Name Command Valid
    [Documentation]  Verify user set name command is valid
    [Arguments]   ${command}

    # Set name for user ID
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  ${command}

    # Check command is valid or not
    Should Not Contain  ${data_resp}    Invalid command
    Should Not Contain  ${data_resp}    Unspecified error

Verify Set Name Command Functional
    [Documentation]  Verify user set name command functional

    # Check user is exist
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  user list

    ${resp}=  Get Lines Containing String  ${data_resp}  ${name_test}
    @{word}=  Split String  ${resp}
    Should Be Equal  @{word}[0]  ${user_id}
    Should Be Equal  @{word}[1]  ${name_test}

Verify Enable Command Valid
    [Documentation]  Verify user enable command is valid

    # Enable user ID
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command   user enable ${user_id}

    # Check command is valid or not
    Should Not Contain  ${data_resp}    Invalid command
    Should Not Contain  ${data_resp}    Unspecified error

Verify Enable Command Functional
    [Documentation]  Verify user enable command functional
    [Arguments]   ${command}

    # Check if user is enabled
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Manual Command
    ...  ${user_name}  ${user_password}  ${command}

    ${resp}=  Get Lines Containing String  ${data_resp}  ${user_name}
    @{word}=  Split String  ${resp}
    Should Be Equal  @{word}[1]  ${user_name}

Verify Disable Command Valid
    [Documentation]  Verify user disable command is valid

    # Disable user id
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command   user disable ${user_id}

    # Check command is valid or not
    Should Not Contain  ${data_resp}    Invalid command
    Should Not Contain  ${data_resp}    Unspecified error

Verify Disable Command Functional
    [Documentation]  Verify user disable command functional
    [Arguments]  ${command}

    # Check if user is disable
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Manual Command
    ...  ${user_name}  ${user_password}  ${command}

    Run Keyword If  '${error}' != 'FAIL'  Fail
    Should Contain  ${data_resp}    Unable to establish IPMI

Verify Privilege Of User After Setting
    [Documentation]  Verify the privilege of user after setting

    # Get the current privilege level of 1 user and compare with created user
    Get Current User Privilege
    Should Be Equal  ${priv_data}  ADMINISTRATOR

    # Set the new privilege level for this user
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user priv ${User_ID} 0x02 0x01

    # Confirm if the user has the new privilege level
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  user list

    ${resp}=  Get Lines Containing String  ${data_resp}  ${user_name}
    @{word}=  Split String  ${resp}
    Should Be Equal  @{word}[5]  USER

Test Teardown For Set Password Command
    [Documentation]  Test Teardown For Set Password Command

    # Restore password defaul
    Set User Password

Test Teardown For User Set Name Command
    [Documentation]  Collect FFDC and Remove User

    # Rename the user to original
    Run Keyword And Ignore Error  Run External IPMI Standard Command
    ...  user set name ${user_id} ${user_name}

    FFDC On Test Case Fail

Test Teardown For User Enable Command
    [Documentation]  Collect FFDC and Recover system

    # Restore user to original status
    Run Keyword And Ignore Error  Run External IPMI Standard Command
    ...  user enable ${user_id}

    FFDC On Test Case Fail

Test Teardown For User Disable Command
    [Documentation]  Collect FFDC and Restore System

    # Restore user to default created status.
    Run Keyword And Ignore Error  Run External IPMI Standard Comman
    ...  user enable ${user_id}

    FFDC On Test Case Fail

Test Teardown For User Privilege Command
    [Documentation]  Collect FFDC and Return current privilege

    # Restore privilege for user
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command
    ...  user priv ${User_ID} 0x04 0x01

    FFDC On Test Case Fail
