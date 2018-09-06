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
${interface}   xyz.openbmc_project.Inventory.FRU
${in_chassis}  xyz.openbmc_project.Inventory.FRU.Chassis
${in_board}    xyz.openbmc_project.Inventory.FRU.Board
${in_product}  xyz.openbmc_project.Inventory.FRU.Product

*** Test Cases ***

Verify FRU Info Via DBus Interface
    [Documentation]  Verify FRU Info of chassis board product.
    [Tags]  Verify_FRU_Info_Via_DBus_Interface

    Verify FRU Interface Exists On DBus

    Verify The Valid Of FRU Information

Verify Custom Fields Of FRU Was Updated
    [Documentation]  Verify the FRU custom fields updated.
    [Tags]  Verify_Custom_Fields_Of_FRU_Was_Updated
    [Teardown]  Teardown For Custom Fields Of FRU

    Verify Custom Fields Updating For Chassis Area

    Verify Custom Fields Updating For Board Area

    Verify Custom Fields Updating For Product Area

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

Verify Custom Fields Updating For Chassis Area
    [Documentation]  Verify custom fields updating for chassis area

    #Update the value for custom fields
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_CHASSIS}
    ...  ${SPACE}${in_chassis} Custom_Field_5 s "AmpereComputing"
    BMC Execute Command  ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s

    #Check the value updated with expected
    ${data_chassis}=  Read Properties  ${HOST_CHASSIS}

    Should Be Equal  ${data_chassis["Custom_Field_5"]}  AmpereComputing

Verify Custom Fields Updating For Board Area
    [Documentation]  Verify custom fields updating for board area

    #Update the value for custom fields
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_BOARD}
    ...  ${SPACE}${in_board} Custom_Field_5 s "AmpereComputing"
    BMC Execute Command  ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s

    #Check the value updated with expected
    ${data_board}=  Read Properties  ${HOST_BOARD}

    Should Be Equal  ${data_board["Custom_Field_5"]}  AmpereComputing

Verify Custom Fields Updating For Product Area
    [Documentation]  Verify custom fields updating for product area

    #Update the value for custom fields
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_PRODUCT}
    ...  ${SPACE}${in_product} Custom_Field_5 s "AmpereComputing"
    BMC Execute Command  ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s

    #Check the value updated with expected
    ${data_product}=  Read Properties  ${HOST_PRODUCT}

    Should Be Equal  ${data_product["Custom_Field_5"]}  AmpereComputing

Teardown For Custom Fields Of FRU
    [Documentation]  Do teardown for custom fields of FRU

    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_CHASSIS}
    ...  ${SPACE}${in_chassis} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s
    # restore Custom_Field_5 for board object
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_BOARD}
    ...  ${SPACE}${in_board} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s

    # restore Custom_Field_5 for product object
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_PRODUCT}
    ...  ${SPACE}${in_product} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}
    # Waiting 10 seconds to write eeprom effectly
    Sleep  10s

    FFDC On Test Case Fail
