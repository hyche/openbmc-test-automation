*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/rest_client.robot
Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/redfish_client.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/bmc_network_utils.robot
Resource            ../../lib/logging_utils.robot
Library             ../../lib/ipmi_utils.py
Variables           ../../data/ipmi_raw_cmd_table.py
Library             ../../lib/gen_misc.py

Test Teardown       FFDC On Test Case Fail

*** Variables ***

${new_mc_id}=  HOST
${allowed_temp_diff}=  ${1}
${allowed_power_diff}=  ${10}
${revision}=  ${128}
${expected_file_path}  ./tests/ipmi/expected_json/dev_id.json

${HOST_UUID}=  ${HOST_INVENTORY_URI}fru0/multirecord

*** Test Cases ***

Verify IPMI SEL Version
    [Documentation]  Verify IPMI SEL's version info.
    [Tags]  Verify_IPMI_SEL_Version

    ${version_info}=  Get IPMI SEL Setting  Version
    ${setting_status}=  Fetch From Left  ${version_info}  (
    ${setting_status}=  Evaluate  $setting_status.replace(' ','')

    Should Be True  ${setting_status} >= 1.5
    Should Contain  ${version_info}  v2 compliant  case_insensitive=True


Verify Empty SEL
    [Documentation]  Verify empty SEL list.
    [Tags]  Verify_Empty_SEL

    Delete Error Logs And Verify

    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify Supported Cipher List
    [Documentation]  Execute all supported cipher levels and verify.
    [Tags]  Verify_Supported_Cipher_List

    :FOR  ${cipher_level}  IN  @{valid_cipher_list}
    \  ${status}=  Execute IPMI Command With Cipher  ${cipher_level}
    \  Should Be Equal  ${status}  ${0}


Verify Unsupported Cipher List
    [Documentation]  Execute all unsupported cipher levels and verify error.
    [Tags]  Verify_Unsupported_Cipher_List

    :FOR  ${cipher_level}  IN  @{unsupported_cipher_list}
    \  ${status}=  Execute IPMI Command With Cipher  ${cipher_level}
    \  Should Be Equal  ${status}  ${1}


Verify Supported Cipher List Via Lan Print
    [Documentation]  Verify supported cipher list via IPMI lan print command.
    [Tags]  Verify_Supported_Cipher_List_Via_Lan_Print

    ${network_info_dict}=  Get Lan Print Dict
    # Example 'RMCP+ Cipher Suites' entry: 3,17
    ${cipher_list}=  Evaluate
    ...  map(int, $network_info_dict['RMCP+ Cipher Suites'].split(','))
    Lists Should Be Equal  ${cipher_list}  ${valid_cipher_list}


Verify Supported Cipher Via Getciphers
    [Documentation]  Verify supported chiper list via IPMI getciphers command.
    [Tags]  Verify_Supported_Cipher_Via_Getciphers

    ${output}=  Run IPMI Standard Command  channel getciphers ipmi
    # Example of getciphers command output:
    # ID   IANA    Auth Alg        Integrity Alg   Confidentiality Alg
    # 3    N/A     hmac_sha1       hmac_sha1_96    aes_cbc_128
    # 17   N/A     hmac_sha256     sha256_128      aes_cbc_128

    ${report}=  Outbuf To Report  ${output}
    # Make list from the 'id' column in the report.
    ${cipher_list}=  Evaluate  [int(x['id']) for x in $report]
    Lists Should Be Equal  ${cipher_list}  ${valid_cipher_list}


Verify Disabling And Enabling IPMI Via Host
    [Documentation]  Verify disabling and enabling IPMI via host.
    [Tags]  Verify_Disabling_And_Enabling_IPMI_Via_Host
    [Teardown]  Run Inband IPMI Standard Command  lan set 1 access on

    # Disable IPMI and verify
    Run Inband IPMI Standard Command  lan set 1 access off
    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print

    # Enable IPMI and verify
    Run Inband IPMI Standard Command  lan set 1 access on
    ${lan_print_output}=  Run External IPMI Standard Command  lan print

    ${openbmc_host_name}  ${openbmc_ip}  ${openbmc_short_name}=
    ...  Get Host Name IP  host=${OPENBMC_HOST}  short_name=1
    Should Contain  ${lan_print_output}  ${openbmc_ip}


Set Asset Tag With Valid String Length
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length

    # Allowed MAX characters length for asset tag name is 63.
    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Run Keyword  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${random_string}


Set Asset Tag With Invalid String Length
    [Documentation]  Verify error while setting invalid asset tag via IPMI.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length

    # Any string more than 63 character is invalid for asset tag.
    ${random_string}=  Generate Random String  64

    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  dcmi set_asset_tag ${random_string}
    Should Contain  ${resp}  Parameter out of range  ignore_case=True


Set Asset Tag With Valid String Length Via REST
    [Documentation]  Set valid asset tag via REST and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length_Via_REST

    ${random_string}=  Generate Random String  63
    ${args}=  Create Dictionary  data=${random_string}
    Write Attribute  /xyz/openbmc_project/inventory/system  AssetTag
    ...  data=${args}

    ${asset_tag}=  Read Attribute  /xyz/openbmc_project/inventory/system
    ...  AssetTag
    Should Be Equal As Strings  ${asset_tag}  ${random_string}


Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String

    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${cmd_output}=  Run IPMI Standard Command  dcmi get_mc_id_string

    # Extract management controller ID from cmd_output.
    ${initial_mc_id}=  Fetch From Right  ${cmd_output}  :${SPACE}

    # Set the management controller ID string to other value.
    # Example:
    # Set Management Controller Identifier String Command: HOST

    Set Management Controller ID String  ${new_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${new_mc_id}

    # Set the value back to the initial value and verify.
    Set Management Controller ID String  ${initial_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${initial_mc_id}


Test Management Controller ID String Status via IPMI
    [Documentation]  Test management controller ID string status via IPMI.
    [Tags]  Test_Management_Controller_ID_String_Status_via_IPMI

    # Disable management controller ID string status via IPMI and verify.
    Run IPMI Standard Command  dcmi set_conf_param dhcp_config 0x00
    Verify Management Controller ID String Status  disable

    # Enable management controller ID string status via IPMI and verify.
    Run IPMI Standard Command  dcmi set_conf_param dhcp_config 0x01
    Verify Management Controller ID String Status  enable


Test Management Controller ID String Status via Raw IPMI
    [Documentation]  Test management controller ID string status via IPMI.
    [Tags]  Test_Management_Controller_ID_String_Status_via_Raw_IPMI

    # Disable management controller ID string status via raw IPMI and verify.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['conf_param']['Disabled'][0]}
    Verify Management Controller ID String Status  disable

    # Enable management controller ID string status via raw IPMI and verify.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['conf_param']['Enabled'][0]}
    Verify Management Controller ID String Status  enable


Verify Chassis Identify via IPMI
    [Documentation]  Verify "chassis identify" using IPMI command.
    [Tags]  Verify_Chassis_Identify_via_IPMI

    # Set to default "chassis identify" and verify that LED blinks for 15s.
    Run IPMI Standard Command  chassis identify
    Verify Identify LED State  Blink

    Sleep  15s
    Verify Identify LED State  Off

    # Set "chassis identify" to 10s and verify that the LED blinks for 10s.
    Run IPMI Standard Command  chassis identify 10
    Verify Identify LED State  Blink

    Sleep  10s
    Verify Identify LED State  Off


Verify Chassis Identify Off And Force Identify On via IPMI
    [Documentation]  Verify "chassis identify" off
    ...  and "force identify on" via IPMI.
    [Tags]  Verify_Chassis_Identify_Off_And_Force_Identify_On_via_IPMI

    # Set the LED to "Force Identify On".
    Run IPMI Standard Command  chassis identify force
    Verify Identify LED State  Blink

    # Set "chassis identify" to 0 and verify that the LED turns off.
    Run IPMI Standard Command  chassis identify 0
    Verify Identify LED State  Off


Test Watchdog Reset Via IPMI And Verify Using REST
    [Documentation]  Test watchdog reset via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Reset_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Resetting the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog reset

    # Verify the watchdog is reset using REST after an interval of 1000ms.
    Sleep  1000ms
    ${watchdog_time_left}=
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be True
    ...  ${watchdog_time_left}<${1200000} and ${watchdog_time_left}>${2000}
    ...  msg=Watchdog timer didn't reset.


Test Watchdog Off Via IPMI And Verify Using REST
    [Documentation]  Test watchdog off via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Off_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Turn off the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog off

    # Verify the watchdog is off using REST
    ${watchdog_state}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal  ${watchdog_state}  ${0}
    ...  msg=msg=Verification failed for watchdog off check.


Test Watchdog Get Via IPMI
    [Documentation]  Test watchdog get via IPMI
    [Tags]  Test_Watchdog_Get_Via_IPMI

    Check Watchdog Get After Set Initial Countdown  ${321}


Test Watchdog Off Via IPMI
    [Documentation]  Test watchdog off via IPMI
    [Tags]  Test_Watchdog_Off_Via_IPMI

    # Check watchdog off result
    ${resp} =  Run IPMI Standard Command  mc watchdog off
    Should Contain  ${resp}  timer stopped  ignore_case=True
    Should Not Contain  ${resp}  Failed  ignore_case=True
    ...  msg=Command return Failed

    # Verify with watchdog get
    ${resp} =  Run IPMI Standard Command  mc watchdog get
    ${value} =  Get Key Value From Output  ${resp}  Watchdog Timer Is
    Should Contain  ${value}  Stopped  msg=Wrong watchdog timer state


Test Watchdog Reset Via IPMI
    [Documentation]  Test watchdog reset via IPMI
    [Tags]  Test_Watchdog_Reset_Via_IPMI

    # Check watchdog reset result
    ${resp} =  Run IPMI Standard Command  mc watchdog reset
    Should Contain  ${resp}  countdown restarted  ignore_case=True
    Should Not Contain  ${resp}  Failed  ignore_case=True
    ...  msg=Command return Failed

    # Wait 1 second and verify with watchdog get
    sleep  1000ms
    ${resp} =  Run IPMI Standard Command  mc watchdog get
    ${value} =  Get Key Value From Output  ${resp}  Watchdog Timer Is
    Should Contain  ${value}  Started/Running  msg=Wrong watchdog timer state
    ${value} =  Get Key Value From Output  ${resp}  Present Countdown
    ${value} =  Fetch From Left  ${value}  ${SPACE}
    Should Not Be Equal As Integers  ${value}  ${0}  msg=Countdown is zero


Test Ambient Temperature Via IPMI
    [Documentation]  Test ambient temperature via IPMI and verify using REST.
    [Tags]  Test_Ambient_Temperature_Via_IPMI

    #        Entity ID                       Entity Instance    Temp. Readings
    # Inlet air temperature(40h)                      1               +19 C
    # CPU temperature sensors(41h)                    5               +51 C
    # CPU temperature sensors(41h)                    6               +50 C
    # CPU temperature sensors(41h)                    7               +50 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    9               +50 C
    # CPU temperature sensors(41h)                    10              +48 C
    # CPU temperature sensors(41h)                    11              +49 C
    # CPU temperature sensors(41h)                    12              +47 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    16              +51 C
    # CPU temperature sensors(41h)                    24              +50 C
    # CPU temperature sensors(41h)                    32              +43 C
    # CPU temperature sensors(41h)                    40              +43 C
    # Baseboard temperature sensors(42h)              1               +35 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Inlet air temperature
    ...  msg="Unable to get inlet temperature via DCMI".
    ${ambient_temp_line}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Inlet air temperature  case-insensitive

    ${ambient_temp_ipmi}=  Fetch From Right  ${ambient_temp_line}  +
    ${ambient_temp_ipmi}=  Remove String  ${ambient_temp_ipmi}  ${SPACE}C

    ${ambient_temp_rest}=  Read Attribute
    ...  ${SENSORS_URI}temperature/ambient  Value

    # Example of ambient temperature via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 35000,
    #  "CriticalLow": 0,
    #  "Scale": -3,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
    #  "Value": 21775,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 25000,
    #  "WarningLow": 0

    # Get temperature value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 21775 * (10 power -3) = 21775/1000

    ${ambient_temp_rest}=  Evaluate  ${ambient_temp_rest}/1000
    ${ipmi_rest_temp_diff}=
    ...  Evaluate  abs(${ambient_temp_rest} - ${ambient_temp_ipmi})

    Should Be True  ${ipmi_rest_temp_diff} <= ${allowed_temp_diff}
    ...  msg=Ambient temperature above allowed threshold ${allowed_temp_diff}.


Verify Get DCMI Capabilities
    [Documentation]  Verify get DCMI capabilities command output.
    [Tags]  Verify_Get_DCMI_Capabilities

    ${cmd_output}=  Run IPMI Standard Command  dcmi discover

    @{supported_capabilities}=  Create List
    # Supported DCMI capabilities:
    ...  Mandatory platform capabilties
    ...  Optional platform capabilties
    ...  Power management available
    ...  Managebility access capabilties
    ...  In-band KCS channel available
    # Mandatory platform attributes:
    ...  200 SEL entries
    ...  SEL automatic rollover is enabled
    # Optional Platform Attributes:
    ...  Slave address of device: 0h (8bits)(Satellite/External controller)
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: 1 is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    :FOR  ${capability}  IN  @{supported_capabilities}
    \  Should Contain  ${cmd_output}  ${capability}  ignore_case=True
    ...  msg=Supported DCMI capabilities not present.


Test Power Reading Via IPMI With Host Off
    [Documentation]  Test power reading via IPMI with host off state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Off

    REST Power Off  stack_mode=skip  quiet=1

    Wait Until Keyword Succeeds  1 min  20 sec  Verify Power Reading


Test Power Reading Via IPMI With Host Booted
    [Documentation]  Test power reading via IPMI with host booted state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Booted

    REST Power On  stack_mode=skip  quiet=1

    # For a good power reading take a 3 samples for 15 seconds interval and
    # average it out.

    Wait Until Keyword Succeeds  1 min  20 sec  Verify Power Reading


Test Power Reading Via IPMI Raw Command
    [Documentation]  Test power reading via IPMI raw command and verify
    ...  using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_Raw_Command

    # Response data structure of power reading command output via IPMI.
    # 1        Completion Code. Refer to section 8, DCMI Completion Codes.
    # 2        Group Extension Identification = DCh
    # 3:4      Current Power in watts

    REST Power On  stack_mode=skip  quiet=1

    Wait Until Keyword Succeeds  1 min  20 sec  Verify Power Reading Via Raw Command


Test Baseboard Temperature Via IPMI
    [Documentation]  Test baseboard temperature via IPMI and verify using REST.
    [Tags]  Test_Baseboard_Temperature_Via_IPMI

    # Example of IPMI dcmi get_temp_reading output:
    #        Entity ID                       Entity Instance    Temp. Readings
    # Inlet air temperature(40h)                      1               +19 C
    # CPU temperature sensors(41h)                    5               +51 C
    # CPU temperature sensors(41h)                    6               +50 C
    # CPU temperature sensors(41h)                    7               +50 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    9               +50 C
    # CPU temperature sensors(41h)                    10              +48 C
    # CPU temperature sensors(41h)                    11              +49 C
    # CPU temperature sensors(41h)                    12              +47 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    16              +51 C
    # CPU temperature sensors(41h)                    24              +50 C
    # CPU temperature sensors(41h)                    32              +43 C
    # CPU temperature sensors(41h)                    40              +43 C
    # Baseboard temperature sensors(42h)              1               +35 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Baseboard temperature sensors
    ...  msg="Unable to get baseboard temperature via DCMI".
    ${baseboard_temp_line}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Baseboard temperature  case-insensitive=True

    ${baseboard_temp_ipmi}=  Fetch From Right  ${baseboard_temp_line}  +
    ${baseboard_temp_ipmi}=  Remove String  ${baseboard_temp_ipmi}  ${SPACE}C

    ${baseboard_temp_rest}=  Read Attribute
    ...  /xyz/openbmc_project/sensors/temperature/pcie  Value
    ${baseboard_temp_rest}=  Evaluate  ${baseboard_temp_rest}/1000

    Should Be True
    ...  ${baseboard_temp_rest} - ${baseboard_temp_ipmi} <= ${allowed_temp_diff}
    ...  msg=Baseboard temperature above allowed threshold ${allowed_temp_diff}.


Retrieve Default Gateway Via IPMI And Verify Using REST
    [Documentation]  Retrieve default gateway from LAN print using IPMI.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_REST

    # Fetch "Default Gateway" from IPMI LAN print.
    ${default_gateway_ipmi}=  Fetch Details From LAN Print  Default Gateway IP

    # Verify "Default Gateway" using REST.
    Read Attribute  ${NETWORK_MANAGER}/config  DefaultGateway
    ...  expected_value=${default_gateway_ipmi}


Retrieve MAC Address Via IPMI And Verify Using REST
    [Documentation]  Retrieve MAC Address from LAN print using IPMI.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_REST

    # Fetch "MAC Address" from IPMI LAN print.
    ${mac_address_ipmi}=  Fetch Details From LAN Print  MAC Address

    # Verify "MAC Address" using REST.
    ${mac_address_rest}=  Get BMC MAC Address
    Should Be Equal  ${mac_address_ipmi}  ${mac_address_rest}
    ...  msg=Verification of MAC address from lan print using IPMI failed.


Retrieve Network Mode Via IPMI And Verify Using REST
    [Documentation]  Retrieve network mode from LAN print using IPMI.
    [Tags]  Retrieve_Network_Mode_Via_IPMI_And_Verify_Using_REST

    # Fetch "Mode" from IPMI LAN print.
    ${network_mode_ipmi}=  Fetch Details From LAN Print  Source

    # Verify "Mode" using REST.
    ${network_mode_rest}=  Read Attribute
    ...  ${NETWORK_MANAGER}/eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of network setting failed.
    ...  ELSE IF  '${network_mode_ipmi}' == 'DHCP'
    ...  Should Be Equal  ${network_mode_rest}  ${1}
    ...  msg=Verification of network setting failed.


Retrieve IP Address Via IPMI And Verify With BMC Details
    [Documentation]  Retrieve IP address from LAN print using IPMI.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_With_BMC_Details

    # Fetch "IP Address" from IPMI LAN print.
    ${ip_addr_ipmi}=  Fetch Details From LAN Print  IP Address

    # Verify the IP address retrieved via IPMI with BMC IPs.
    ${ip_address_rest}=  Get BMC IP Info
    Validate IP On BMC  ${ip_addr_ipmi}  ${ip_address_rest}


Verify Get Device ID
    [Documentation]  Verify get device ID command output.
    [Tags]  Verify_Get_Device_ID

    # Example of get device ID command output:
    # Device ID                 : 0
    # Device Revision           : 0
    # Firmware Revision         : 2.01
    # IPMI Version              : 2.0
    # Manufacturer ID           : 42817
    # Manufacturer Name         : Unknown (0xA741)
    # Product ID                : 16975 (0x424f)
    # Product Name              : Unknown (0x424F)
    # Device Available          : yes
    # Provides Device SDRs      : yes
    # Additional Device Support :
    #     Sensor Device
    #     SEL Device
    #     FRU Inventory Device
    #     Chassis Device
    # Aux Firmware Rev Info     :
    #     0x04
    #     0x38
    #     0x00
    #     0x03

    ${expected}=  Parse Json From File  ${expected_file_path}
    ${mc_info}=  Get MC Info

    Should Be Equal  ${mc_info['device_id']}  ${expected['id']}
    Should Be Equal  ${mc_info['device_revision']}  ${expected['revision']}

    # Get firmware revision from mc info command output i.e. 2.01
    ${ipmi_fw_major_version}  ${ipmi_fw_minor_version}=
    ...  Split String  ${mc_info['firmware_revision']}  .
    # Convert minor firmware version from BCD format to integer. i.e. 01 to 1
    ${ipmi_fw_minor_version}=  Convert To Integer  ${ipmi_fw_minor_version}

    # Get BMC version from BMC CLI i.e. 2.2 from "v2.2-253-g00050f1"
    ${bmc_version_full}=  Get BMC Version
    ${bmc_version}=
    ...  Remove String Using Regexp  ${bmc_version_full}  ^[^0-9]+  [^0-9\.].*

    # Get major and minor version from BMC version i.e. 2 and 1 from 2.1
    ${bmc_major_version}  ${bmc_minor_version}=
    ...  Split String  ${bmc_version}  .

    Should Be Equal As Strings  ${ipmi_fw_major_version}  ${bmc_major_version}
    ...  msg=Major version mis-match.
    Should Be Equal As Strings  ${ipmi_fw_minor_version}  ${bmc_minor_version}
    ...  msg=Minor version mis-match.

    Should Be Equal  ${mc_info['ipmi_version']}  2.0

    # TODO: Verify Manufacturer and Product IDs directly from json file.
    # Reference : openbmc/openbmc-test-automation#1244
    Should Be Equal  ${mc_info['manufacturer_id']}  ${expected['manuf_id']}
    ${product_ids}=   Split String  ${mc_info['product_id']}
    ${product_id}=   Get From List  ${product_ids}  0
    Should Be Equal  ${product_id}  ${expected['prod_id']}

    Should Be Equal  ${mc_info['device_available']}  yes
    # Compare with revision as mask to check device revision enable or not
    Run Keyword If   '${expected['revision']}' != '${revision}'
    ...  Should Be Equal  ${mc_info['provides_device_sdrs']}  no
    ...  ELSE
    ...  Should Be Equal  ${mc_info['provides_device_sdrs']}  yes
    Should Contain  ${mc_info['additional_device_support']}  Sensor Device
    Should Contain  ${mc_info['additional_device_support']}  SEL Device
    Should Contain
    ...  ${mc_info['additional_device_support']}  FRU Inventory Device
    Should Contain  ${mc_info['additional_device_support']}  Chassis Device

    # From aux_firmware_rev_info field ['0x04', '0x38', '0x00', '0x03']
    ${bmc_aux_version}=  Catenate
    ...  SEPARATOR=
    ...  ${mc_info['aux_firmware_rev_info'][0][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][1][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][2][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][3][2:]}

    Should Be Equal As Integers
    ...  ${bmc_aux_version}  ${expected['aux']}
    ...  msg=BMC aux version ${bmc_aux_version} does not match expected value.


Verify SDR Info
    [Documentation]  Verify sdr info command output.
    [Tags]  Verify_SDR_Info

    # Example of SDR info command output:
    # SDR Version                         : 0x51
    # Record Count                        : 216
    # Free Space                          : unspecified
    # Most recent Addition                :
    # Most recent Erase                   :
    # SDR overflow                        : no
    # SDR Repository Update Support       : unspecified
    # Delete SDR supported                : no
    # Partial Add SDR supported           : no
    # Reserve SDR repository supported    : no
    # SDR Repository Alloc info supported : no

    ${sdr_info}=  Get SDR Info
    Should Be Equal  ${sdr_info['sdr_version']}  0x51

    # Get sensor count from "sdr elist all" command output.
    ${sensor_count}=  Get Sensor Count
    Should Be Equal As Strings
    ...  ${sdr_info['record_count']}  ${sensor_count}

    Should Be Equal  ${sdr_info['free_space']}  unspecified
    Should Be Equal  ${sdr_info['most_recent_addition']}  ${EMPTY}
    Should Be Equal  ${sdr_info['most_recent_erase']}  ${EMPTY}
    Should Be Equal  ${sdr_info['sdr_overflow']}  no
    Should Be Equal  ${sdr_info['sdr_repository_update_support']}  unspecified
    Should Be Equal  ${sdr_info['delete_sdr_supported']}  no
    Should Be Equal  ${sdr_info['partial_add_sdr_supported']}  no
    Should Be Equal  ${sdr_info['reserve_sdr_repository_supported']}  no
    Should Be Equal  ${sdr_info['sdr_repository_alloc_info_supported']}  no


Test Valid IPMI Channels Supported
    [Documentation]  Verify IPMI channels supported on a given system.
    [Tags]  Test_Valid_IPMI_Channels_Supported

    ${channel_count}=  Get Physical Network Interface Count

    # Note: IPMI network channel logically starts from 1.
    :FOR  ${channel_number}  IN RANGE  1  ${channel_count}
    \  Run External IPMI Standard Command  lan print ${channel_number}


Test Invalid IPMI Channel Response
    [Documentation]  Verify invalid IPMI channels supported response.
    [Tags]  Test_Invalid_IPMI_Channel_Response

    ${channel_count}=  Get Physical Network Interface Count

    # To target invalid channel, increment count.
    ${channel_number}=  Evaluate  ${channel_count} + 1

    # Example of invalid channel:
    # $ ipmitool -I lanplus -H xx.xx.xx.xx -P password lan print 3
    # Get Channel Info command failed: Parameter out of range
    # Invalid channel: 3

    ${stdout}=  Run External IPMI Standard Command
    ...  lan print ${channel_number}  fail_on_err=${0}
    Should Contain  ${stdout}  Invalid channel
    ...  msg=IPMI channel ${channel_number} is invalid but seen working.

Verify IPMI User List
    [Documentation]  This test case verifies ipmi user list command.
    [Tags]  Verify_IPMI_User_List

    # Example of output for "user list command" :
    # ID  Name         Callin  Link Auth    IPMI Msg   Channel Priv Limit
    # 1                    true    true       true       NO ACCESS
    # 2   admin            false   false      true       ADMINISTRATOR
    # 3   Admin            false   false      true       ADMINISTRATOR
    # 4                    false   false      true       ADMINISTRATOR

    # Verify if user root or admin is exist.

    ${resp}=  Run External IPMI Standard Command  user list
    ${list}=  Get Lines Matching Regexp
    ...  ${resp}  root|admin  partial_match=true
    @{word}=  Split String  ${list}
    Run Keyword If  '@{word}[4]' != 'true' or '@{word}[5]' != 'ADMINISTRATOR'
    ...  Should Be Equal  @{word}[10]  true
    Run Keyword If  '@{word}[4]' != 'true' or '@{word}[5]' != 'ADMINISTRATOR'
    ...  Should Be Equal  @{word}[11]  ADMINISTRATOR

Verify IPMI MC Self Test
    [Documentation]  Verify ipmi mc selftest command.
    [Tags]  Verify_IPMI_MC_Self_Test

    Verify Selftest Command Valid  mc selftest
    Verify Selftest Functional  Selftest  passed

Verify IPMI MC GUID Test
    [Documentation]  Verify ipmi mc guid command.
    [Tags]  Verify_IPMI_MC_GUID_Test

    Verify MC GUID Command Valid
    Verify Value Of GUID

Verify IPMI MC Getenables Command
    [Documentation]  Verify ipmi mc getenables command.
    [Tags]  Verify_IPMI_MC_Getenables_Command

    Verify MC Getenables Command Valid
    Verify MC Getenables Command Functional

*** Keywords ***

Get Key Value From Output
    [Documentation]  Get key value after colon and strip whitespace.
    [Arguments]  ${buffer}  ${key}

    # Example:
    # Buffer:
    # Watchdog Timer Use:     SMS/OS (0x04)
    # Watchdog Timer Is:      Stopped
    # Watchdog Timer Actions: No action (0x00)
    # Pre-timeout interval:   0 seconds
    # Timer Expiration Flags: 0x00
    # Initial Countdown:      300 sec
    # Present Countdown:      300 sec
    #
    # Call: Get Key Value From Output  ${buffer}  Watchdog Timer Is
    # Return: Started/Running

    ${line} =  Get Lines Containing String  ${buffer}  ${key}
    Should Be String  ${line}  msg=Not found key: ${key}
    Should Contain  ${line}  :
    ${output} =  Fetch From Right  ${line}  :${SPACE}
    ${output} =  Strip String  ${output}
    [Return]  ${output}


Check Watchdog Get After Set Initial Countdown
    [Documentation]  Set watchdog initial countdown with raw IPMI then
    ...  check get response. Argument: time in second
    [Arguments]  ${time}

    ${time} =  Convert To Integer  ${time}
    ${time_lsb} =  Evaluate  (${time}*10) & 0xFF
    ${time_lsb} =  Convert To Hex  ${time_lsb}  prefix=0x  length=2
    ${time_msb} =  Evaluate  ((${time}*10) >> 8) & 0xFF
    ${time_msb} =  Convert To Hex  ${time_msb}  prefix=0x  length=2

    # Set initial countdown via raw IPMI don't care result
    # We choose timer use: SMS/OS, no action
    Run IPMI Standard Command  raw 0x06 0x24 0x04 0x00 0x01 0x00 ${time_lsb} ${time_msb}

    ${resp} =  Run IPMI Standard Command  mc watchdog get

    # Example of watchdog get result:
    #
    # Watchdog Timer Use:     SMS/OS (0x04)
    # Watchdog Timer Is:      Stopped
    # Watchdog Timer Actions: No action (0x00)
    # Pre-timeout interval:   0 seconds
    # Timer Expiration Flags: 0x00
    # Initial Countdown:      300 sec
    # Present Countdown:      300 sec

    ${value} =  Get Key Value From Output  ${resp}  Watchdog Timer Use
    Should Contain  ${value}  SMS/OS  msg=Wrong Watchdog Timer Use
    ${output} =  Get Key Value From Output  ${resp}  Initial Countdown
    ${output} =  Fetch From Left  ${output}  ${SPACE}

    Should Be Equal As Strings  ${output}  ${time}  msg=Wrong Initial Countdown


Get Sensor Count
    [Documentation]  Get sensors count using "sdr elist all" command.

    # Example of "sdr elist all" command output:
    # BootProgress     | 03h | ok  | 34.2 |
    # OperatingSystemS | 05h | ok  | 35.1 |
    # AttemptsLeft     | 07h | ok  | 34.1 |
    # occ0             | 08h | ok  | 210.1 | Device Disabled
    # occ1             | 09h | ok  | 210.2 | Device Disabled
    # p0_core0_temp    | 11h | ns  |  3.1 | Disabled
    # cpu0_core0       | 12h | ok  | 208.1 | Presence detected
    # p0_core1_temp    | 14h | ns  |  3.2 | Disabled
    # cpu0_core1       | 15h | ok  | 208.2 | Presence detected
    # p0_core2_temp    | 17h | ns  |  3.3 | Disabled
    # ..
    # ..
    # ..
    # ..
    # ..
    # ..
    # fan3             | 00h | ns  | 29.4 | Logical FRU @35h
    # bmc              | 00h | ns  |  6.1 | Logical FRU @3Ch
    # ethernet         | 00h | ns  |  1.1 | Logical FRU @46h

    ${output}=  Run IPMI Standard Command  sdr elist all
    ${sensor_list}=  Get Lines Matching Regexp
    ...  ${output}  ok|ns|nc|cr|nr  partial_match=true
    ${sensor_list}=  Split String  ${sensor_list}  \n
    ${sensor_count}=  Get Length  ${sensor_list}
    [Return]  ${sensor_count}

Set Management Controller ID String
    [Documentation]  Set the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID String to be set

    ${set_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string ${string}


Get Management Controller ID String And Verify
    [Documentation]  Get the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID string

    ${get_mc_id}=  Run IPMI Standard Command  dcmi get_mc_id_string
    Should Contain  ${get_mc_id}  ${string}
    ...  msg=Command failed: get_mc_id.


Set Watchdog Enabled Using REST
    [Documentation]  Set watchdog Enabled field using REST.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  Integer value (eg. "0-Disabled", "1-Enabled").

    ${value_dict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}/attr/Enabled
    ...  data=${value_dict}


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Run External IPMI Standard Command  lan print
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}


Verify Power Reading
    [Documentation]  Get dcmi power reading via IPMI.

    # Example of power reading command output via IPMI.
    # Instantaneous power reading:                   235 Watts
    # Minimum during sampling period:                235 Watts
    # Maximum during sampling period:                235 Watts
    # Average power reading over sample period:      235 Watts
    # IPMI timestamp:                                Thu Jan  1 00:00:00 1970
    # Sampling period:                               00000000 Seconds.
    # Power reading state is:                        deactivated

    ${power_reading}=  Get IPMI Power Reading

    ${host_state}=  Get Host State
    Run Keyword If  '${host_state}' == 'Off'
    ...  Should Be Equal  ${power_reading['instantaneous_power_reading']}  0
    ...  msg=Power reading not zero when power is off.

    Run Keyword If  '${power_reading['instantaneous_power_reading']}' != '0'
    ...  Verify Power Reading Using REST  ${power_reading['instantaneous_power_reading']}


Verify Power Reading Via Raw Command
    [Documentation]  Get dcmi power reading via IPMI raw command.

    ${ipmi_raw_output}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['power_reading']['Get'][0]}

    @{raw_output_list}=  Split String  ${ipmi_raw_output}  ${SPACE}

    # On successful execution of raw IPMI power reading command, completion
    # code does not come in output. So current power value will start from 2
    # byte instead of 3.

    ${power_reading_ipmi_raw_3_item}=  Get From List  ${raw_output_list}  2
    ${power_reading_ipmi_raw_3_item}=
    ...  Convert To Integer  0x${power_reading_ipmi_raw_3_item}

    ${power_reading_rest}=  Read Attribute
    ...  ${SENSORS_URI}power/total_power  Value

    # Example of power reading via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 3100000000,
    #  "CriticalLow": 0,
    #  "Scale": -6,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Watts",
    #  "Value": 228000000,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 3050000000,
    #  "WarningLow": 0

    # Get power value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 228000000 * (10 power -6) = 228000000/1000000

    ${power_reading_rest}=  Evaluate  ${power_reading_rest}/1000000
    ${ipmi_rest_power_diff}=
    ...  Evaluate  abs(${power_reading_rest} - ${power_reading_ipmi_raw_3_item})

    Should Be True  ${ipmi_rest_power_diff} <= ${allowed_power_diff}
    ...  msg=Power Reading above allowed threshold ${allowed_power_diff}.


Verify Management Controller ID String Status
    [Documentation]  Verify management controller ID string status via IPMI.
    [Arguments]  ${status}

    # Example of dcmi get_conf_param command output:
    # DHCP Discovery method   :
    #           Management Controller ID String is disabled
    #           Vendor class identifier DCMI IANA and Vendor class-specific Informationa are disabled
    #   Initial timeout interval        : 4 seconds
    #   Server contact timeout interval : 120 seconds
    #   Server contact retry interval   : 64 seconds

    ${resp}=  Run IPMI Standard Command  dcmi get_conf_param
    ${resp}=  Get Lines Containing String  ${resp}
    ...  Management Controller ID String  case_insensitive=True
    Should Contain  ${resp}  ${status}
    ...  msg=Management controller ID string is not ${status}


Verify Power Reading Using REST
    [Documentation]  Verify power reading using REST.
    [Arguments]  ${power_reading}

    # Description of argument(s):
    # power_reading  IPMI Power reading

    ${power_reading_rest}=  Read Attribute
    ...  ${SENSORS_URI}power/total_power  Value

    # Example of power reading via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 3100000000,
    #  "CriticalLow": 0,
    #  "Scale": -6,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Watts",
    #  "Value": 228000000,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 3050000000,
    #  "WarningLow": 0

    # Get power value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 228000000 * (10 power -6) = 228000000/1000000
    ${power_reading_rest}=  Evaluate  ${power_reading_rest}/1000000
    ${ipmi_rest_power_diff}=
    ...  Evaluate  abs(${power_reading_rest} - ${power_reading})

    Should Be True  ${ipmi_rest_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Get Physical Network Interface Count
    [Documentation]  Return valid physical network interfaces count.

    # Example:
    # link/ether 22:3a:7f:70:92:cb brd ff:ff:ff:ff:ff:ff
    # link/ether 0e:8e:0d:6b:e9:e4 brd ff:ff:ff:ff:ff:ff

    ${mac_entry_list}=  Get BMC MAC Address List
    ${mac_unique_list}=  Remove Duplicates  ${mac_entry_list}
    ${physical_interface_count}=  Get Length  ${mac_unique_list}

    [Return]  ${physical_interface_count}


Execute IPMI Command With Cipher
    [Documentation]  Execute IPMI command with a given cipher level value.
    [Arguments]  ${cipher_level}

    # Description of argument(s):
    # cipher_level  IPMI chipher level value
    #               (e.g. "1", "2", "3", "15", "16", "17").

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ipmitool -I lanplus -C ${cipher_level} -P${SPACE}${IPMI_PASSWORD}
    ...  ${SPACE}${HOST}${SPACE}${OPENBMC_HOST}${SPACE}mc info

    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd}
    [Return]  ${rc}

Verify Selftest Command Valid
    [Documentation]  Verify if the command is valid or not.
    [Arguments]  ${command}

    ${error}  ${selftest_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  ${command}
    Should Not Contain  ${selftest_resp}    Invalid command
    Should Not Contain  ${selftest_resp}    Unspecified error
    Set Test Variable  ${selftest_resp}

Verify Selftest Functional
    [Documentation]  Verify keywords in specific line.
    [Arguments]  ${line_keyword}  ${keyword}

    ${result}=  Get Lines Containing String  ${selftest_resp}  ${line_keyword}
    Should Contain  ${result}  ${keyword}

Verify MC GUID Command Valid
    [Documentation]  Verify if the command is valid or not.

    # Run command mc guid
     ${error}  ${data_guid}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  mc guid

    # Check command is valid
    Should Not Contain  ${data_guid}    Invalid command
    Should Not Contain  ${data_guid}    Unspecified error
    Set Test Variable  ${data_guid}

Verify Value Of GUID
    [Documentation]  Verify value of guid with uuid

    # Check UUID from FRU
    ${data_uuid}=  Read Properties  ${HOST_UUID}

    # Compate with GUID
    ${system_guid}=
    ...  Get Lines Containing String  ${data_guid}  System GUID
    Should Contain    ${system_guid}   ${data_uuid["Record_1"]}

Verify MC Getenables Command Valid
    [Documentation]  Verify if the command is valid or not.

    # Run command mc getenables
    ${error}  ${data_resp}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command   mc getenables

    # Check command is valid or not
    Should Not Contain  ${data_resp}    Invalid command
    Should Not Contain  ${data_resp}    Unspecified error
    Set Test Variable   ${data_resp}

Verify MC Getenables Command Functional
    [Documentation]  Verify mc getenable command function

    # Check field if's supported will be enable
    # Verify if SEL is enabled

    ${output} =  Get Key Value From Output  ${data_resp}  System Event Logging
    Should Be Equal As Strings  '${output}'  'enabled'
    ...  msg=System Event Logging is Disable

    # TODO: Verify other fields
