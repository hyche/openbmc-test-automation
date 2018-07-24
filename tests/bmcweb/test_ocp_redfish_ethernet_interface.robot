*** Settings ***
Resource  ../../lib/redfish.robot
Resource  ../../lib/rest_client.robot
Resource  ../../lib/bmc_network_utils.robot
Resource  ../../lib/openbmc_ffdc.robot

Force Tags  Bmcweb_Test

Test Setup     Test Setup Execution

*** Variables ***
${eth_id}                   eth0
${eth_uri}                  SEPARATOR=${Empty}  ${REDFISH_MANAGERS_URI}  bmc/
...                         EthernetInterfaces/  ${eth_id}
${valid_ipv4}               10.38.15.201
${valid_ipv4_subnet_mask}   255.255.252.0
${valid_ipv4_prefix_len}    ${22}
${valid_ipv4_gateway}       10.38.12.1

*** Test Cases ***
Verify Redfish Ethernet Interface Hostname
    [Documentation]  Verify that the hostname read via bmcweb is the same as the
    ...  hostname configured on system.
    [Tags]  Verify_Redfish_Ethernet_Interface_Hostname

    ${hostname}=  Get From Dictionary  ${ethernet_info}  HostName
    ${sys_hostname}=  Get BMC Hostname

    Should Contain  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.

Verify Redfish Ethernet Interface Fixed Entries
    [Documentation]  Verify all the fixed entries got from GET request to
    ...  bmcweb are correct. According to DSP2049 (EthernetInterface resource)
    [Tags]  Verify_Redfish_Ethernet_Interface_Fixed_Entries
    [Template]  Verify Redfish Fixed Entries

    # Test Entries      # JSON file path
    ${ethernet_info}   ./tests/bmcweb/expected_json/EthernetInterface.json

Add New Valid IPv4 And Delete And Verify
    [Documentation]  Create new IPv4 and verify.
    [Tags]  Add_New_Valid_IPv4_And_Delete_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    Add New IPv4 Via Redfish  ${valid_ipv4}  ${valid_ipv4_subnet_mask}
    ...  ${valid_ipv4_gateway}  ${False}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  valid  # Verify added IPv4

    ${ipv4_info_list}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    Delete IP Via Redfish Given Address  4  ${valid_ipv4}  @{ipv4_info_list}
    Verify IP On BMC  ${valid_ipv4}  error  # Verify deleted IPv4

Delete Non Existing IPv4 Via Redfish And Verify
    [Documentation]  Delete non-existing IPv4 via redfish by assigning null
    ...  entry to request data, and then verify setting.
    [Tags]  Delete_Non_Existing_IPv4_Via_Redfish_And_Verify

    ${ipv4_info_list}=  Get From Dictionary  ${ethernet_info}  IPv4Addresses
    # Assuming there should not have more than 99 IPv4 addresses on one device.
    Delete IP Via Redfish Given Index  4  99  @{ipv4_info_list}

    ${ipv4_info_list_after}=  Redfish Get Property  ${eth_uri}  IPv4Addresses
    Lists Should Be Equal  ${ipv4_info_list}  ${ipv4_info_list_after}

*** Keywords ***
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
    Run Keyword If  '${empty}' == '${False}'  Set To Dictionary  ${created_ipv4}
    ...  Address=${ipv4_addr}  SubnetMask=${subnet_mask}  Gateway=${gateway}
    Append To List  ${ipv4_info_list}  ${created_ipv4}
    ${data}=  Create Dictionary  IPv4Addresses=@{ipv4_info_list}
    Redfish Patch Request  ${eth_uri}  data=${data}

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_RETRY_TIME}
    ...  ${NETWORK_TIMEOUT}

    Sleep  1s  Wait for host to config settings

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
    Redfish Patch Request  ${eth_uri}  data=${data}

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_RETRY_TIME}
    ...  ${NETWORK_TIMEOUT}

    Sleep  1s  Wait for host to config settings.

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

    ${index}=  Set Variable  ${0}
    :FOR  ${ip_info}  IN  @{ip_info_list}
    \  ${addr}=  Get From Dictionary  ${ip_info}  Address
    \  Exit For Loop If  '${addr}' == '${ip_addr}'
    \  ${index}=  Set Variable  ${index + 1}

    Delete IP Via Redfish Given Index  ${type}  ${index}  @{ip_info_list}

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

    ${resp}=  OpenBMC Get Request  ${eth_uri}  timeout=10  quiet=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${ethernet_info}=  To Json  ${resp.content}
    Set Test Variable  ${ethernet_info}
