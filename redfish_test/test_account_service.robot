*** Setting ***
Documentation          Account Service test suite.

Resource               ../lib/redfish_client.robot
Resource               ../lib/bmc_network_utils.robot

Force Tags             redfish

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***
${accounts_uri}         AccountService/Accounts/
${user}                 foo
${user2}                bar
${passw}                dummypassword

*** Test Cases ***

Add Valid User Account And Verify
    [Documentation]  Add valid user account and verify.
    [Tags]  Add_Valid_User_Account_And_Verify
    [Template]  Create User Account

    # username     # expected_results
    ${user}        @{HTTP_SUCCESS}      Password=${passw}

Add User Account Without Password And Verify
    [Documentation]  Add an user account wihout password and verify.
    [Tags]  Add_User_Account_Without_Password_And_Verify
    [Template]  Create User Account

    # username     # expected_results
    ${user2}       @{HTTP_CLIENT_ERROR}

Delete Non Existent User Account And Verify
    [Documentation]  Delete non-existent user account and verify.
    [Tags]  Delete_Non_Existent_User_Account_And_Verify
    [Template]  Delete User Account

    # username      # expected_results
    ${user2}        @{HTTP_CLIENT_ERROR}

Delete Valid User Account And Verify
    [Documentation]  Delete valid user account and verify
    [Tags]  Delete_Valid_User_Account_And_Verify
    [Template]  Delete User Account

    # username      # expected_results
    ${user}         @{HTTP_SUCCESS}

*** Keywords ***

Create User Account
    [Documentation]  Create an account.
    [Arguments]  ${username}  @{expected_results}  &{account}
    # 'RoleId', and 'Enabled' default to User, and True

    # Description of arguments(s):
    # username          A username for login. This is a mandatory argument.
    # expected_results  Expected statuses of creating user account.
    # account           A Dicitonary holds info for creating user account
    #                   (Contains UserName, Password, RoleId and Enabled)

    Set To Dictionary  ${account}  UserName=${username}
    ${resp}=  Redfish Post Request  ${accounts_uri}  ${auth_token}
    ...  data=${account}

    Log To Console  ${resp.content}
    ${status}=  Convert To String  ${resp.status_code}
    List Should Contain Value  ${expected_results}  ${status}

    Run Keyword If  ${status[0]} == 2
    ...      Verify User Existence On BMC  ${username}  valid
    ...  ELSE
    ...      Verify User Existence On BMC  ${username}  invalid

Delete User Account
    [Documentation]  Delete the account.
    [Arguments]  ${username}  @{expected_results}

    # Description of arguments(s):
    # username          The username for deleted account.
    # expected_results  Expected statuses of deleting user account.

    ${user_path}=  Catenate  SEPARATOR=  ${accounts_uri}  ${username}
    ${resp}=  Redfish Delete Request  ${user_path}  ${auth_token}
    ...  resp_check=${0}

    ${status}=  Convert To String  ${resp.status_code}
    List Should Contain Value  ${expected_results}  ${status}
    Verify User Existence On BMC  ${username}  invalid

Verify User Existence On BMC
    [Documentation]  Verify the existence of an user on BMC.
    [Arguments]  ${username}  ${expected_result}

    # Description of arguments(s):
    # username
    # expected_results  Verify for (non) existence.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  grep -w ${username} /etc/passwd  ignore_err=${1}

    Run Keyword If  '${expected_result}' == 'invalid'
    ...      Should Be Equal As Integers  ${rc}  ${1}
    ...      msg=User ${username} does exist.
    ...  ELSE
    ...      Should Be Equal As Integers  ${rc}  ${0}
    ...      msg=User ${username} does not exist.

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
