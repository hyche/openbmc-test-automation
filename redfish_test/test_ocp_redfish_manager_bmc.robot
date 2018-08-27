*** Setting ***
Documentation          This suite tests for Manager Bmc schema version 1.3.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Resource               ../lib/code_update_utils.robot
Library                ../lib/ipmi_utils.py

Force Tags             redfish

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${manager_bmc_uri}           Managers/bmc
${reset_uri}                 Managers/bmc/Actions/Manager.Reset

${file_json}                 ./redfish_test/expected_json/ManagerBmc.json

*** Test Cases ***

Verify Manager BMC All Sessions
    [Documentation]    Verify all of sessions via GET request.
    [Tags]  Verify_Manager_BMC_All_Sessions

    Verify Manager BMC Fixed Sessions

    Verify Manager BMC Flexible Sessions

Verify Manager BMC Reset Action
    [Documentation]    Verify manager BMC reset action by post method.
    [Tags]  Verify_Manager_BMC_Reset_Action

    Verify Manager BMC Reset Action Type  GracefulRestart
    Verify Manager BMC Reset Action Type  ForceRestart

*** Keywords ***

Verify Manager BMC Fixed Sessions
    [Documentation]    Verify all the fixed sessions via GET request.

    Verify Redfish Fixed Entries  ${output_json}  ${file_json}

Verify Manager BMC Flexible Sessions
    [Documentation]  Verify non-fixed fields of computer system.

    Check Manager BMC Reset Type
    Check Manager BMC Type
    Check Manager BMC Power State
    Check Manager BMC Firmware Version
    Check Manager BMC Date Time
    Check Manager BMC Model
    Check Manager BMC UUID

Check Manager BMC UUID
    [Documentation]  Check UUID of manager node.

    Should Not Be Empty  ${output_json["UUID"]}
    Should Be String  ${output_json["UUID"]}
    ${data}=  Set Variable  [0-9a-fA-F]
    Should Match Regexp  ${output_json["UUID"]}
    ...  ^${data}{8}-${data}{4}-${data}{4}-${data}{4}-${data}{12}$

Check Manager BMC Model
    [Documentation]  Check BMC model of manager node.

    Should Not Be Empty  ${output_json["Model"]}
    Should Be String  ${output_json["Model"]}

Check Manager BMC Date Time
    [Documentation]  Check date time and local offset of manager node.

    # Get format date-time exp: "2018-08-01T07:23:03+00:00"
    Should Match Regexp  ${output_json["DateTime"]}
    ...  ^\\d{4}\\-\\d{2}\\-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\+|\\-)\\d{2}:\\d{2}$

    Should Match Regexp  ${output_json["DateTimeLocalOffset"]}
    ...  ^(\\+|\\-)\\d{2}:\\d{2}$

Check Manager BMC Firmware Version
    [Documentation]  Check firmware version of manager node.

    ${bmc_version}=  Get BMC Version
    Should Be Equal As Strings  ${bmc_version}
    ...  "${output_json["FirmwareVersion"]}"

Check Manager BMC Reset Type
    [Documentation]  Check reset type of manager node.

    ${temp}=  Get From Dictionary  ${output_json}  Actions
    ${expected_value}=  Get Manager BMC Items Schema  RESET_TYPE
    List Should Contain Sub List  ${expected_value}
    ...  ${temp["#Manager.Reset"]["ResetType@Redfish.AllowableValues"]}

Check Manager BMC Type
    [Documentation]  Check type of manager node.

    Verify Dynamic Fields  MANAGER_TYPE  ${output_json["ManagerType"]}

Check Manager BMC Power State
    [Documentation]  Check power state of manager node.

    Verify Dynamic Fields  POWER_STATE  ${output_json["PowerState"]}

Verify Dynamic Fields
    [Documentation]  Verify expected keys read from inventory with
    ...  dynamic keys from GET request.
    [Arguments]  ${expected_key}  ${output_value}

    ${expected_value}=  Get Manager BMC Items Schema  ${expected_key}
    Should Contain  ${expected_value}  ${output_value}

Verify Manager BMC Reset Action Type
    [Documentation]  Verify bmc reset action via some types of Redfish.
    [Arguments]  ${type}

    # Reset type:
    # 1. GracefulRestart
    # 2. ForceRestart

    # Execute Post Action
    Execute Post Action  ${type}

    # Check BMC Power State
    # Wait for BMC state  NotReady
    Wait Until Keyword Succeeds  5 min  5 sec  Check BMC IP  False
    Wait Until Keyword Succeeds  5 min  5 sec  Check BMC IP  True

    # Delay 3 minutes to recover the system.
    Sleep  3 min

Execute Post Action
    [Documentation]  Execute bmc reset action via POST request.
    [Arguments]  ${type}

    ${data}=  Create Dictionary  ResetType=${type}
    ${resp}=  Redfish Post Request  ${reset_uri}  ${auth_token}  data=${data}
    ${status_list}=
    ...  Create List  '${HTTP_OK}'  '${HTTP_NO_CONTENT}'  '${HTTP_ACCEPTED}'
    Should Contain  '${status_list}  '${resp.status_code}'

Check BMC IP
    [Documentation]  Check BMC IP via ping command.
    [Arguments]  ${expected_status}

    ${status}=  Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST}
    Should Be Equal As Strings  ${status}  ${expected_status}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

    ${output_json}=  Redfish Get Request  ${manager_bmc_uri}  ${session_id}
    ...  ${auth_token}
    Set Test Variable  ${output_json}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_id}  ${auth_token} =  Redfish Login Request
    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
