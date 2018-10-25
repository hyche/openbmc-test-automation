*** Settings ***
Documentation     Verify stress the FRU property.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.txt
Resource          ../../lib/utils.robot
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

Verify Custom Fields Of FRU For Many Times Writing Data
    [Documentation]  Verify Custom Fields Of FRU For Many Times Writing Data.
    [Tags]  Verify_Custom_Fields_Of_FRU_For_Many_Times_Writing_Data
    [Teardown]  Teardown For Custom Fields Of FRU

    Verify Custom Fields Many Times Writing Data For Chassis
    Verify Custom Fields Many Times Writing Data For Board
    Verify Custom Fields Many Times Writing Data For Product

*** Keywords ***

Verify Custom Fields Many Times Writing Data For Chassis
    [Documentation]  Verify Custom Fields Many Times Writing Data For Chassis

    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_CHASSIS}
    ...  ${SPACE}${in_chassis} Custom_Field_5 s "AmpereComputing"

    #Writing the data for custom fields with 10 times
    : FOR    ${INDEX}    IN RANGE    0    10
    \   BMC Execute Command  ${cmd}
    \   Sleep  5s

    #Check the value updated with expected
    ${data_chassis}=  Read Properties  ${HOST_CHASSIS}
    Should Be Equal  ${data_chassis["Custom_Field_5"]}  AmpereComputing

Verify Custom Fields Many Times Writing Data For Board
    [Documentation]  Verify Custom Fields Many Times Writing Data For Board

    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_BOARD}
    ...  ${SPACE}${in_board} Custom_Field_5 s "AmpereComputing"

    #Writing the data for custom fields with 10 times
    : FOR    ${INDEX}    IN RANGE    0    10
    \   BMC Execute Command  ${cmd}
    \   Sleep  5s

    #Check the value updated with expected
    ${data_board}=  Read Properties  ${HOST_BOARD}
    Should Be Equal  ${data_board["Custom_Field_5"]}  AmpereComputing

Verify Custom Fields Many Times Writing Data For Product
    [Documentation]  Verify Custom Fields Many Times Writing Data For Product

    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_PRODUCT}
    ...  ${SPACE}${in_product} Custom_Field_5 s "AmpereComputing"

    #Writing the data for custom fields with 10 times
    : FOR    ${INDEX}    IN RANGE    0    10
    \   BMC Execute Command  ${cmd}
    \   Sleep  5s

    #Check the value updated with expected
    ${data_product}=  Read Properties  ${HOST_PRODUCT}
    Should Be Equal  ${data_product["Custom_Field_5"]}  AmpereComputing

Teardown For Custom Fields Of FRU
    [Documentation]  Do teardown for custom fields of FRU

    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_CHASSIS}
    ...  ${SPACE}${in_chassis} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}

    # Waiting 5 seconds to write eeprom effectly
    Sleep  5s

    # restore Custom_Field_5 for board object
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_BOARD}
    ...  ${SPACE}${in_board} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}

    # Waiting 5 seconds to write eeprom effectly
    Sleep  5s

    # restore Custom_Field_5 for product object
    ${cmd}=  Catenate  SEPARATOR=
    ...  busctl set-property ${interface} ${HOST_PRODUCT}
    ...  ${SPACE}${in_product} Custom_Field_5 s ""
    BMC Execute Command   ${cmd}

    # Waiting 5 seconds to write eeprom effectly
    Sleep  5s

    FFDC On Test Case Fail
