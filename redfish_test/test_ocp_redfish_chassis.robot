*** Setting ***
Documentation          This suite tests for Chassis schema version 1.4.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py

Force Tags             redfish

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${chassis_uri}           Chassis/1
${chassis_node}          ${HOST_INVENTORY_URI}system/chassis
${file_json}            ./redfish_test/expected_json/Chassis.json

*** Test Cases ***

Verify Chassis All Sessions
    [Documentation]    Verify all of sessions via GET request.
    [Tags]  Verify_Chassis_All_Sessions

    Verify Chassis Fixed Sessions

    Verify Chassis Flexible Sessions

*** Keywords ***

Verify Chassis Fixed Sessions
    [Documentation]    Verify all the fixed sessions via GET request.

    Verify Redfish Fixed Entries  ${output_json}  ${file_json}

Verify Chassis Flexible Sessions
    [Documentation]  Verify non-fixed fields of computer system.

    Run Keyword And Continue On Failure  Check Chassis Type
    Run Keyword And Continue On Failure  Check Chassis FRU Information
    Run Keyword And Continue On Failure  Check Chassis Status

Check Chassis Type
    [Documentation]  Check type of chassis via redfish.

    Verify Flexible Fields  CHASSIS_TYPE  ${output_json["ChassisType"]}

Check Chassis FRU Information
    [Documentation]  Verify FRU information of chassis via redfish.

    ${list}=  Create List  Model  Manufacturer
    ...  SerialNumber  PartNumber  SKU  AssetTag
    ${info}=  Read Properties  ${chassis_node}
    :FOR  ${item}  IN  @{list}
    \  Should Contain  ${info}  ${item}
    \  ...  msg=${item} is not supported on D-BUS.
    \  Should Be Equal As Strings  ${info["${item}"]}  ${output_json["${item}"]}
    \  ...  msg=${item} read via Redfish is not correct.

Check Chassis Status
    [Documentation]  Verify status of chassis via redfish.

    Verify Flexible Fields  STATE  ${output_json["Status"]["State"]}
    Verify Flexible Fields  HEALTH  ${output_json["Status"]["Health"]}

Verify Flexible Fields
    [Documentation]  Verify expected keys getting from inventory with
    ...  flexible keys from GET request.
    [Arguments]  ${expected_key}  ${output_value}

    ${expected_value}=  Get Chassis Items Schema  ${expected_key}
    Should Contain  ${expected_value}  ${output_value}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

    ${output_json}=  Redfish Get Request  ${chassis_uri}  ${session_id}
    ...  ${auth_token}
    Set Test Variable  ${output_json}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_id}  ${auth_token} =  Redfish Login Request
    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}