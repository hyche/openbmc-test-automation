*** Setting ***
Documentation          This suite tests for ComputerSystem schema version 1.5.0

Resource               ../lib/redfish_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py

Force Tags             redfish

Test Setup             Test Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${system_uri}           Systems/1
${reset_uri}            Systems/1/Actions/ComputerSystem.Reset
${chassis_uri}          Chassis/1

${file_json}            ./redfish_test/expected_json/ComputerSystem.json

*** Test Cases ***

Verify Computer System All Sessions
    [Documentation]    Verify all of sessions get from GET request.
    [Tags]  Verify_Computer_System_All_Sessions

    Verify Computer System Fixed Sessions
    Verify Computer System Flexible Sessions

Verify Indicator LED Setting Function
    [Documentation]    Verify indicator LED setting fuction via redfish API.
    [Tags]  Verify_Indicator_LED_Setting_Function

    Verify Indicator LED Status  Off
    Verify Indicator LED Status  Blinking
    Verify Indicator LED Status  Lit

    [Teardown]  Reset Indicator LED Status

Verify Computer System Reset Action
    [Documentation]    Verify computer system reset action by post method.
    [Tags]  Verify_Computer_System_Reset_Action

    Verify System Reset Action Type  ForceOff

    Verify System Reset Action Type  On

    Verify System Reset Action Type  GracefulRestart

    Verify System Reset Action Type  GracefulShutdown

    Verify System Reset Action Type  ForceRestart

Verify Compuer System Bios Version
    [Documentation]    Verify bios version of computer system from Redfish.
    [Tags]  Verify_Computer_System_Bios_Version

    # Verify bios version by comparing to expected value.
    ${value}=  Set Variable  ${output_json["BiosVersion"]}
    Should Not Be Empty  ${value}
    ...  msg=Bios version getting from REDFISH is empty.
    Should Be Equal As Strings  ${value}  %{BIOS_VERSION}

    # %{BIOS_VERSION} : This is pre-define Jenkins Job exported variable.
    # TODO: Get expected Bios version on D-BUS when it is supported.

*** Keywords ***

Verify Computer System Fixed Sessions
    [Documentation]    Verify all the fixed sessions get from GET request.

    Verify Redfish Fixed Entries  ${output_json}  ${file_json}

Verify Computer System Flexible Sessions
    [Documentation]  Verify non-fixed fields of computer system.

    Verify Computer System Hostname
    Verify Computer System Reset Type
    Verify Computer System Type
    Verify Computer System Boot
    Verify Computer System Indicator Led
    Verify Computer System Power State
    Verify Computer System Asset Tag
    Verify Computer System Status
    Verify Computer System Information

    # TODO: Add test case for UUID and BIOS Version when they are supported.

Verify Computer System Hostname
    [Documentation]  Verify the hostname from bmcweb and compare to
    ...  hostname of system.

    ${sys_hostname}=  Get BMC Hostname
    Should Contain  ${sys_hostname}  ${output_json["HostName"]}
    ...  ignore_case=True  msg=Hostname does not exist.

Verify Computer System Reset Type
    [Documentation]  Verify reset types in action field of computer system.

    ${temp}=  Get From Dictionary  ${output_json}  Actions
    ${expected_value}=  Get Computer System Items Schema  RESET_TYPE
    List Should Contain Sub List  ${expected_value}
    ...  ${temp["#ComputerSystem.Reset"]["ResetType@Redfish.AllowableValues"]}

Verify Computer System Type
    [Documentation]  Verify system type of computer system.

    Test Dynamic Fields  SYSTEM_TYPE  ${output_json["SystemType"]}

Verify Computer System Boot
    [Documentation]  Verify boot information for computer system.

    ${temp}=  Get From Dictionary  ${output_json}  Boot
    Test Dynamic Fields  BOOT_ENABLED  ${temp["BootSourceOverrideEnabled"]}
    Test Dynamic Fields  BOOT_MODE  ${temp["BootSourceOverrideMode"]}
    ${expected_value}=  Get Computer System Items Schema  BOOT_SOURCE
    List Should Contain Sub List  ${expected_value}
    ...  ${temp["BootSourceOverrideTarget@Redfish.AllowableValues"]}

Verify Computer System Indicator Led
    [Documentation]  Verify indicator light state of computer system.

    Test Dynamic Fields  INDICATOR_LED  ${output_json["IndicatorLED"]}

Verify Computer System Power State
    [Documentation]  Verify the current power state of the system.

    Test Dynamic Fields  POWER_STATE  ${output_json["PowerState"]}

Verify Computer System Status
    [Documentation]  Verify the status or health properties of a resource.

    Test Dynamic Fields  STATE  ${output_json["Status"]["State"]}
    Test Dynamic Fields  HEALTH  ${output_json["Status"]["Health"]}

Verify Computer System Information
    [Documentation]  Verify FRU properties.

    ${system_list}=  Get Component FRU Info  system
    ${sys_info}=  Get From List  ${system_list}  ${0}
    Should Contain  ${output_json["Manufacturer"]}
    ...  ${sys_info['product_manufacturer']}
    Should Contain  ${output_json["PartNumber"]}
    ...  ${sys_info['product_part_number']}
    Should Contain  ${output_json["Name"]}
    ...  ${sys_info['product_name']}
    Should Contain  ${output_json["SerialNumber"]}
    ...  ${sys_info['product_serial']}

    # TODO: Update code for mutiple system.
    # This is just for single system.

Verify Computer System Asset Tag
    [Documentation]  Verify asset tag of computer system.

    ${asset_tag}=  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${output_json["AssetTag"]}

Test Dynamic Fields
    [Documentation]  Verify expected keys getting from inventory with
    ...  dynamic keys from GET request.
    [Arguments]  ${expected_key}  ${output_value}

    ${expected_value}=  Get Computer System Items Schema  ${expected_key}
    Should Contain  ${expected_value}  ${output_value}

Verify Indicator LED Status
    [Documentation]  Verify indicator led state of computer system.
    [Arguments]  ${led_status}

    # Set indicator led status
    ${new_state}=  Create Dictionary  IndicatorLED=${led_status}
    ${stt}=  Run Keyword And Return Status
    ...  Redfish Patch Request  ${system_uri}  ${auth_token}  data=${new_state}
    Run Keyword If  '${stt}'=='False'  Log  Patch Request Fail
    Sleep  5 sec

    # Read indicator led status
    ${resp}=  Redfish Get Request  ${system_uri}  ${session_id}
    ...  ${auth_token}

    # Compare indicator led status.
    Should Be Equal As Strings  ${resp["IndicatorLED"]}  ${led_status}

Reset Indicator LED Status
    [Documentation]  Reset indicator led to the initial state.

    # Set indicator led intial status.
    Run Keyword If  '${output_json["IndicatorLED"]}'=='Off'
    ...  Set System Led State  identify  Off
    ...  ELSE IF  '${output_json["IndicatorLED"]}'=='Blinking'
    ...  Set System Led State  identify  Blink
    ...  ELSE  Set System Led State  identify  On

Verify System Reset Action Type
    [Documentation]  Verify system reset action via some types of Redfish.
    [Arguments]  ${type}

    # Reset type:
    # 1. On
    # 2. ForceOff
    # 3. GracefulRestart
    # 4. GracefulShutdown
    # 5. ForceRestart

    # Execute Post Action
    Execute Post Action  ${type}

    # Check Power State Via Reset Types
    Run Keyword If  '${type}'=='ForceOff' or '${type}'=='GracefulShutdown'
    ...  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  Off
    ...  ELSE IF  '${type}'=='On'
    ...  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  On
    ...  ELSE  Run Keywords
    ...  Wait Until Keyword Succeeds  1 min  2 sec
    ...  Check Power State  Off
    ...  AND  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Check Power State  On

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
    [Documentation]  Check the power state of host or chassis via redfish.
    [Arguments]  ${state}

    # Get Host State
    ${resp}=  Redfish Get Request  ${system_uri}  ${session_id}
    ...  ${auth_token}

    # Compare Host State
    Should Be Equal As Strings  ${resp["PowerState"]}  ${state}
    ...  msg=Host power is not change as expected

    # Get Chassis State
    ${resp}=  Redfish Get Request  ${chassis_uri}  ${session_id}
    ...  ${auth_token}

    # Compare Chassis State
    Should Be Equal As Strings  ${resp["PowerState"]}  ${state}
    ...  msg=Chassis power is not change as expected

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

    ${output_json}=  Redfish Get Request  ${system_uri}  ${session_id}
    ...  ${auth_token}
    Set Test Variable  ${output_json}


Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
