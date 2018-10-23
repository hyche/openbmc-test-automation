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
${chassis_node}          ${HOST_INVENTORY_URI}fru0/chassis
${product_node}          ${HOST_INVENTORY_URI}fru0/product
${file_json}            ./redfish_test/expected_json/Chassis.json
${reset_uri}             Chassis/1/Actions/Chassis.Reset

*** Test Cases ***

Verify Chassis All Sessions
    [Documentation]    Verify all of sessions via GET request.
    [Tags]  Verify_Chassis_All_Sessions

    Verify Chassis Fixed Sessions

    Verify Chassis Flexible Sessions

Verify Chassis Reset Action
    [Documentation]    Verify chassis reset action by post method.
    [Tags]  Verify_Chassis_Reset_Action

    Verify Chassis Reset Action Type  ForceOff

    Verify Chassis Reset Action Type  On

    Verify Chassis Reset Action Type  ForceRestart

*** Keywords ***

Verify Chassis Fixed Sessions
    [Documentation]    Verify all the fixed sessions via GET request.

    Verify Redfish Fixed Entries  ${output_json}  ${file_json}

Verify Chassis Flexible Sessions
    [Documentation]  Verify non-fixed fields of computer system.

    Run Keyword And Continue On Failure  Check Chassis Type
    Run Keyword And Continue On Failure  Check Chassis FRU Information
    Run Keyword And Continue On Failure  Check Chassis Status
    Run Keyword And Continue On Failure  Check Chassis IndicatorLED

Check Chassis Type
    [Documentation]  Check type of chassis via redfish.

    Verify Flexible Fields  CHASSIS_TYPE  ${output_json["ChassisType"]}

Check Chassis FRU Information
    [Documentation]  Verify FRU information of chassis via redfish.

    ${info}=  Read Properties  ${chassis_node}
    Should Be Equal As Strings  ${info["Serial_Number"]}  ${output_json["SerialNumber"]}
    Should Be Equal As Strings  ${info["Part_Number"]}  ${output_json["PartNumber"]}
    Should Be Equal As Strings  ${info["SKU"]}  ${output_json["SKU"]}
    Should Be Equal As Strings  ${info["Asset_Tag"]}  ${output_json["AssetTag"]}

    # TODO: Chassis Area doesn't include Manufacturer and Model value
    #       This values are used from Product Area
    #       Update the test case after Chassis Area support this info
    ${info}=  Read Properties  ${product_node}
    Should Be Equal As Strings  ${info["Manufacturer"]}  ${output_json["Manufacturer"]}
    Should Be Equal As Strings  ${info["Name"]}  ${output_json["Model"]}

Check Chassis Status
    [Documentation]  Verify status of chassis via redfish.

    Verify Flexible Fields  STATE  ${output_json["Status"]["State"]}
    Verify Flexible Fields  HEALTH  ${output_json["Status"]["Health"]}

Check Chassis IndicatorLED
    [Documentation]  Verify property of IndicatorLED via redfish.

    Verify Dynamic Fields  INDICATOR_LED  ${output_json["IndicatorLED"]}

Verify Flexible Fields
    [Documentation]  Verify expected keys getting from inventory with
    ...  flexible keys from GET request.
    [Arguments]  ${expected_key}  ${output_value}

    ${expected_value}=  Get Chassis Items Schema  ${expected_key}
    Should Contain  ${expected_value}  ${output_value}

Verify Chassis Reset Action Type
    [Documentation]  Verify system reset action via some types of Redfish.
    [Arguments]  ${type}

    # Reset type:
    # 1. On
    # 2. ForceOff
    # 3. ForceRestart

    # Execute Post Action
    Execute Post Action  ${type}

    # Check Power State Via Reset Types
    Run Keyword If  '${type}'=='ForceOff'
    ...  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  off
    ...  ELSE IF  '${type}'=='On'
    ...  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  on
    ...  ELSE  Run Keywords
    ...  Wait Until Keyword Succeeds  1 min  2 sec
    ...  Check Power State  off
    ...  AND  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  on

    # Delay 3 minutes to recover the system.
    Sleep  3 min

Execute Post Action
    [Documentation]  Execute system reset action via POST request.
    [Arguments]  ${type}

    ${data}=  Create Dictionary  ResetType=${type}
    ${resp}=  Redfish Post Request  ${reset_uri}  ${auth_token}  data=${data}
    ${status_list}=
    ...  Create List  '${HTTP_OK}'  '${HTTP_NO_CONTENT}'  '${HTTP_ACCEPTED}'
    Should Contain  '${status_list}  '${resp.status_code}'

Check Power State
    [Documentation]  Check the power state of chassis
    [Arguments]  ${expected_state}

    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}    ${expected_state}

Verify Dynamic Fields
    [Documentation]  Verify expected keys getting from inventory with
    ...  dynamic keys from GET request.
    [Arguments]  ${expected_key}  ${output_value}

    ${expected_value}=  Get Computer System Items Schema  ${expected_key}
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
