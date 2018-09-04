*** Settings ***
Documentation     Verify FRU property.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.txt
Resource          ../../lib/utils.robot
Library           Collections
Test Teardown     FFDC On Test Case Fail

*** Variables ***

${HOST_CHASSIS}=  ${HOST_INVENTORY_URI}fru0/chassis
${HOST_BOARD}=  ${HOST_INVENTORY_URI}fru0/board
${HOST_PRODUCT}=  ${HOST_INVENTORY_URI}fru0/product

*** Test Cases ***

Verify FRU Info Via DBus Interface
    [Documentation]  Verify FRU Info of chassis board product.
    [Tags]  Verify_FRU_Info_Via_DBus_Interface

    Verify FRU Interface Exists On DBus

    Verify The Valid Of FRU Information

*** Keywords ***

Verify FRU Interface Exists On DBus
    [Documentation]  Verify FRU interface exists on D-Bus or not.

    # Check the FRU interface exist on D-Bus
    ${data_board}=  Read Properties  ${HOST_BOARD}
    Set Test Variable  ${data_board}

    # TODO: check Chassis/Product area

Verify The Valid Of FRU Information
    [Documentation]  Verify the information of FRU.

    # Compare the FRU information with expected
    Verify The Valid Of Board

    # TODO: verify Chassis/Product areas
    #Verify The Valid Of Chassis
    #Verify The Valid Of Product

Verify The Valid Of Board
    [Documentation]  Verify the information of Board area

    # TODO: Check other fields
    Should Be Equal  ${data_board["Manufacturer"]}  AmpereComputing(R)

