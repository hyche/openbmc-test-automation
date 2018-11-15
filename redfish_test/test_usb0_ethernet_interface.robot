*** Settings ***
Documentation          This suite tests for usb0 ethernet interface.

Resource  ../lib/redfish_client.robot
Resource  ../lib/rest_client.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/state_manager.robot

Test Setup     Test Setup Execution
Test TearDown  Test Teardown Execution

*** Variables ***
${eth_id}                     usb0
${eth_uri}                    Managers/bmc/EthernetInterfaces/${eth_id}
${valid_ipv4}                 1.1.1.1

*** Test Cases ***

Verify USB0 Ethernet Interface

    [Documentation]  Verify usb0 ethernet interface is valid when the host power on.
    [Tags]  Verify_USB0_Ethernet_Interface

    Verify USB0 Node Exist
    Verify USB0 Ethernet Interface Vaild

*** Keywords ***

Verify USB0 Node Exist
    [Documentation]  Verify existence of the usb0 resource.
    [Tags]  Verify_USB0_Node_Exist

    # Do REST GET request and return the result
    ${resp}=  Redfish Get Request  ${eth_uri}  ${session_id}
    ...  ${auth_token}
    [Return]  ${resp}
    # Verify response code: Should be 200

Verify USB0 Ethernet Interface Vaild
    [Documentation]  Verify ipv4 address of usb0 ethernet interface.

    ${resp}=   Verify USB0 Node Exist

    # Get the expected value
    ${expected_value}=  Get From List  ${resp["IPv4Addresses"]}  0

    # Compare expected with actual value
    Should Be Equal  ${expected_value["Address"]}  ${valid_ipv4}

Test Setup Execution
    [Documentation]  Do the pre test setup.

    # Initiate host power on
    Initiate Host Boot

    # Login and return authorization token
    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${session_id}
    Set Test Variable  ${auth_token}

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${session_id}

    Redfish Delete Request  ${session_uri}  ${auth_token}

