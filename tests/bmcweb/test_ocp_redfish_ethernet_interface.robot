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

*** Keywords ***
Test Setup Execution
    [Documentation]  Do the pre test setup.

    ${resp}=  OpenBMC Get Request  ${eth_uri}  timeout=10  quiet=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${ethernet_info}=  To Json  ${resp.content}
    Set Test Variable  ${ethernet_info}
