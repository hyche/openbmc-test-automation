*** Settings ***
Documentation          This suite tests for OCP Redfish Ethernet interface.

Resource  ../lib/redfish_client.robot
Resource  ../lib/rest_client.robot
Resource  ../lib/bmc_network_utils.robot

Force Tags  redfish

Test Setup     Test Setup Execution
Test TearDown  Test Teardown Execution

*** Variables ***
${eth_id}                     eth0
${eth_uri}                    Managers/bmc/EthernetInterfaces/${eth_id}
${valid_ipv4}                 10.6.6.6
${valid_ipv4_2}               10.6.6.7
${valid_ipv4_subnet_mask}     255.255.255.0
${valid_ipv4_subnet_mask_2}   255.255.252.0
${valid_ipv4_prefix_len}      ${24}
${valid_ipv4_gateway}         10.6.6.1
${valid_ipv4_gateway_2}       10.6.4.1

*** Test Cases ***
Verify Redfish Ethernet Interface Hostname
    [Documentation]  Verify that the hostname read via bmcweb is the same as the
    ...  hostname configured on system.
    [Tags]  Verify_Redfish_Ethernet_Interface_Hostname

    ${hostname}=  Get From Dictionary  ${ethernet_info}  HostName
    ${sys_hostname}=  Get BMC Hostname

    Should Contain  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.

Verify Ethernet Interface Interface Enabled
    [Documentation]  Get InterfaceEnabled Property from Redfish with GET request
    ...  and check with value from REST server.
    [Tags]  Verify_Ethernet_Interface_Interface_Enabled

    # Get InterfaceEnabled property
    ${rf_value}=  Get From Dictionary  ${ethernet_info}  InterfaceEnabled

    # Verify with expected value from REST
    ${rf_value}=  Set Variable If  ${rf_value}  ${1}  ${0}
    ${expected_result}=  Read Attribute  ${NETWORK_MANAGER}${eth_id}  Functional
    Should Be Equal  ${rf_value}  ${expected_result}

Verify Redfish Ethernet Interface Fixed Entries
    [Documentation]  Verify all the fixed entries got from GET request to
    ...  bmcweb are correct. According to DSP2049 (EthernetInterface resource)
    [Tags]  Verify_Redfish_Ethernet_Interface_Fixed_Entries
    [Template]  Verify Redfish Fixed Entries

    # Test Entries      # JSON file path
    ${ethernet_info}   ./redfish_test/expected_json/EthernetInterface.json

Add New Valid IPv4 And Delete And Verify
    [Documentation]  Create new IPv4 and verify.
    [Tags]  Add_New_Valid_IPv4_And_Delete_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    Add New IPv4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_subnet_mask}
    ...  ${valid_ipv4_gateway}  ${False}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  valid  # Verify added IPv4

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Delete IP Via Redfish Given Address  4  ${valid_ipv4}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  error  # Verify deleted IPv4

Verify Ethernet Interface MAC Address
    [Documentation]  Verify that the MAC address read via redfish is same as
    ...  MAC address configured on system.
    [Tags]  Verify_Ethernet_Interface_MAC_Address

    # Get MAC address on system
    ${macaddr}=  Read Attribute  ${NETWORK_MANAGER}/eth0  MACAddress

    # Compare MAC address read from redfish
    Should Not Be Empty  ${ethernet_info["MACAddress"]}
    ...  msg=MAC Address read via redfish is empty.
    Should Be Equal As Strings  ${macaddr}  ${ethernet_info["MACAddress"]}
    ...  msg=MAC Address read via redfish is not correct.

Delete Non Existing IPv4 Via Redfish And Verify
    [Documentation]  Delete non-existing IPv4 via redfish by assigning null
    ...  entry to request data, and then verify setting.
    [Tags]  Delete_Non_Existing_IPv4_Via_Redfish_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    # Assuming there should not have more than 99 IPv4 addresses on one device.
    Delete IP Via Redfish Given Index  4  99  @{ipv4_info_list}

    ${ipv4_info_list_after}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Lists Should Be Equal  ${ipv4_info_list}  ${ipv4_info_list_after}

Change IPv4 With Empty Entry Via Redfish And Verify
    [Documentation]  Change existing IPv4 via redfish with empty entry
    ...  (ie. {}) in request data, and then verify.
    [Tags]  Change_IPv4_With_Empty_Entry_Via_Redfish_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    Add New IPv4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_subnet_mask}
    ...  ${valid_ipv4_gateway}  ${False}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  valid    # Verify added IPv4

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Change IPv4 Via Redfish  ${valid_ipv4}  ${Empty}  ${Empty}  ${Empty}
    ...  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  valid    # verify unchanged IPv4

    Delete IP Via Redfish Given Address  4  ${valid_ipv4}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  error    # Verify deleted IPv4

Change IPv4 With Only Address Via Redfish And Verify
    [Documentation]  Change existing IPv4 via redfish with only address
    ...  is provided in request data, and then verify.
    [Tags]  Change_IPv4_With_Only_Address_Via_Redfish_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    Add New IPv4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_subnet_mask}
    ...  ${valid_ipv4_gateway}  ${False}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  valid    # Verify added IPv4

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Change IPv4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_2}  ${Empty}  ${Empty}
    ...  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  error    # Verify deleted old IPv4
    Verify IP On BMC  ${valid_ipv4_2}  valid  # Verify changed IPv4

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Delete IP Via Redfish Given Address  4  ${valid_ipv4_2}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4_2}  error  # Verify deleted IPv4

Change IPv4 With Full Fields Via Redfish And Verify
    [Documentation]  Change existing IPv4 via redfish with full fields
    ...  are provided in request data, and then verify.
    [Tags]  Change_IPv4_With_Full_Fields_Via_Redfish_And_Verify

    Verify After Adding New IPV4 Via Redfish  ${valid_ipv4}
    ...  ${valid_ipv4_subnet_mask}  ${valid_ipv4_gateway}

    Verify After Changing IPV4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_2}
    ...  ${valid_ipv4_subnet_mask_2}  ${valid_ipv4_gateway_2}

    Verify After Delete IPV4 Via Redfish  ${valid_ipv4_2}

*** Keywords ***

Verify After Adding New IPV4 Via Redfish
    [Documentation]  Add new IPV4 and verify via redfish.
    [Arguments]  ${ipv4_addr}  ${subnet_mask}  ${gateway}

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    Add New IPv4 Via Redfish  ${ipv4_addr}  ${subnet_mask}
    ...  ${gateway}  ${False}  @{ipv4_info_list}
    Verify IP On BMC  ${ipv4_addr}  valid  # Verify added IPv4

Verify After Changing IPV4 Via Redfish
    [Documentation]  Change IPV4 and verify via redfish.
    [Arguments]  ${ipv4_addr}  ${ipv4_addr_2}  ${subnet_mask}  ${gateway}

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Change IPv4 Via Redfish  ${ipv4_addr}  ${ipv4_addr_2}  ${subnet_mask}
    ...  ${gateway}  @{ipv4_info_list}
    Verify IP On BMC  ${ipv4_addr}  error    # Verify deleted old IPv4
    Verify IP On BMC  ${ipv4_addr_2}  valid  # Verify changed IPv4

Verify After Delete IPV4 Via Redfish
    [Documentation]  Delete IPV4 after changing and verify via redfish.
    [Arguments]  ${ipv4_addr_2}

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    ...  ${auth_token}
    Delete IP Via Redfish Given Address  4  ${ipv4__addr_2}  @{ipv4_info_list}
    Verify IP On BMC  ${ipv4_addr_2}  error  # Verify deleted IPv4

Add New IPv4 Via Redfish
    [Documentation]  Add the IPv4 via redfish
    [Arguments]  ${ipv4_addr}  ${subnet_mask}  ${gateway}  ${empty}
    ...  @{ipv4_info_list}

    # Description of argument(s):
    # ipv4_addr       IPv4 addr to be created
    # subnet_mask     subnet mask
    # gateway         gateway
    # empty           indicate if the created IP is empty (eg. True -> {})
    # ipv4_info_list  List of ipv4 info got from GET request
    #                 eg: [{
    #                        "Address": "10.xx.xx.xx",
    #                        "AddressOrigin": "Static",
    #                        "Gateway": "10.xx.xx.xx",
    #                        "SubnetMask": "255.xxx.xxx.xxx"
    #                      }, {...}, ...]

    ${created_ipv4}=  Create Dictionary
    Run Keyword If  '${empty}' == '${False}'  Set To Dictionary
    ...  ${created_ipv4}  Address=${ipv4_addr}  SubnetMask=${subnet_mask}
    ...  Gateway=${gateway}
    Append To List  ${ipv4_info_list}  ${created_ipv4}
    ${data}=  Create Dictionary  IPv4Addresses=@{ipv4_info_list}
    Redfish Patch Request  ${eth_uri}  ${auth_token}  data=${data}
    Wait For Network Configuration

Delete IP Via Redfish Given Index
    [Documentation]  Delete the IP via redfish with known index.
    [Arguments]  ${type}  ${ip_index}  @{ip_info_list}

    # Description of argument(s):
    # type          IP type (eg. 4 or 6). Should be a string.
    # ip_index      IP index for the deleted IP.
    # ip_info_list  List of ip info got from GET request
    #               eg: [{
    #                        "Address": "10.xx.xx.xx",
    #                        "AddressOrigin": "Static",
    #                        "Gateway": "10.xx.xx.xx",
    #                        "SubnetMask": "255.xxx.xxx.xxx"
    #                    }, {...}, ...]

    ${length}=  Get Length  ${ip_info_list}
    Run Keyword If  ${ip_index} < ${length}
    ...  Set List Value  ${ip_info_list}  ${ip_index}  ${None}
    ...  ELSE
    ...  Append To List  ${ip_info_list}  ${None}

    ${key}=  Catenate  SEPARATOR=${Empty}  IPv  ${type}  Addresses
    ${data}=  Create Dictionary  ${key}=@{ip_info_list}
    Redfish Patch Request  ${eth_uri}  ${auth_token}  data=${data}
    Wait For Network Configuration

Delete IP Via Redfish Given Address
    [Documentation]  Delete the IP via redfish with known address
    [Arguments]  ${type}  ${ip_addr}  @{ip_info_list}

    # Description of argument(s):
    # type          IP type (eg. 4 or 6). Should be a string.
    # ip_addr       IP address to be deleted.
    # ip_info_list  List of ip info got from GET request
    #               eg: [{
    #                        "Address": "10.xx.xx.xx",
    #                        "AddressOrigin": "Static",
    #                        "Gateway": "10.xx.xx.xx",
    #                        "SubnetMask": "255.xxx.xxx.xxx"
    #                    }, {...}, ...]

    ${index}=  Find Property Index In List Of Dictionaries
    ...  Address  ${ip_addr}  @{ip_info_list}
    Delete IP Via Redfish Given Index  ${type}  ${index}  @{ip_info_list}

Change IPv4 Via Redfish
    [Documentation]  Change the IPv4 via redfish.
    [Arguments]  ${old_addr}  ${ipv4_addr}  ${subnet_mask}  ${gateway}
    ...  @{ipv4_info_list}

    # Description of argument(s):
    # old_addr       Old IPv4 address to be replaced by new IP address. Also,
    #                used for finding its index to perform the replacement.
    # ipv4_addr      New IPv4 address. If Empty, not assign it into passed data.
    # subnet_mask    New SubnetMask. If Empty, not assign it into passed data.
    # gateway        New Gateway. If Empty, not assign it into passed data.
    # ipv4_info_list List of ip info got from GET request
    #                eg: [{
    #                        "Address": "10.xx.xx.xx",
    #                        "AddressOrigin": "Static",
    #                        "Gateway": "10.xx.xx.xx",
    #                        "SubnetMask": "255.xxx.xxx.xxx"
    #                     }, {...}, ...]

    ${length}=  Get Length  ${ipv4_info_list}
    ${index}=  Find Property Index In List Of Dictionaries
    ...  Address  ${old_addr}  @{ipv4_info_list}
    Run Keyword If  ${index} == ${length}
    ...  Fail  msg=IPv4Address ${old_addr} Not Found

    # Prepare inputs
    ${ipv4_info}=  Create Dictionary
    Run Keyword If  '${ipv4_addr}' != '${Empty}'
    ...  Set To Dictionary  ${ipv4_info}  Address  ${ipv4_addr}
    Run Keyword If  '${subnet_mask}' != '${Empty}'
    ...  Set To Dictionary  ${ipv4_info}  SubnetMask  ${subnet_mask}
    Run Keyword If  '${gateway}' != '${Empty}'
    ...  Set To Dictionary  ${ipv4_info}  Gateway  ${gateway}

    Set List Value  ${ipv4_info_list}  ${index}  ${ipv4_info}

    # Send request
    ${data}=  Create Dictionary  IPv4Addresses=@{ipv4_info_list}
    Redfish Patch Request  ${eth_uri}  ${auth_token}  data=${data}
    Wait For Network Configuration

Wait For Network Configuration
    [Documentation]  Wait for configuration of network (eg. delete, create ip)
    [Arguments]  ${config_time}=2s

    # Description of argument(s):
    # config_time     Time to wait for configuration.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_RETRY_TIME}
    ...  ${NETWORK_TIMEOUT}
    Sleep  ${config_time}  Wait for host to config settings.

Verify IP On BMC
    [Documentation]  Verify IP on BMC. Exists or not exists.
    [Arguments]  ${ip_addr}  ${expected_result}

    # Description of argument(s):
    # ip_addr          IP address of the system.
    # expected_result  Expected status of network setting configuration.

    ${ip_data}=  Get BMC IP Info
    ${status}=  Run Keyword And Return Status
    ...  Should Contain Match  ${ip_data}  ${ip_addr}/*
    ...  msg=IP address does not exist.

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Allowing the configuration of an invalid IP.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Not allowing the configuration of a valid IP.

Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

    ${ethernet_info}=  Redfish Get Request  ${eth_uri}  ${session_id}
    ...  ${auth_token}
    Set Test Variable  ${ethernet_info}

Test Teardown Execution
    [Documentation]  Do the test teardown.

    ${session_id}  ${auth_token} =  Redfish Login Request
    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}
