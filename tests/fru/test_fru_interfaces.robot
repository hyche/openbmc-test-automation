*** Settings ***
Documentation     Verify FRU property.

Resource          ../../lib/ipmi_client.robot
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
${HOST_MULTIRECORD}=  ${HOST_INVENTORY_URI}fru0/multirecord
${interface}   xyz.openbmc_project.Inventory.FRU
${in_chassis}  xyz.openbmc_project.Inventory.FRU.Chassis
${in_board}    xyz.openbmc_project.Inventory.FRU.Board
${in_product}  xyz.openbmc_project.Inventory.FRU.Product
${FRU_ID}      ${3}

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

Verify Get FRU Inventory Area Infor
    [Documentation]  Verify FRU Inventory Area Info command.
    [Tags]      Verify_Get_FRU_Inventory_Area_Infor

    Verify FRU Interface Exists On DBus

    Verify Value Of FRU Inventory Area Infor

Verify Read FRU Data Command
    [Documentation]  Verify Read FRU data via IPMI command.
    [Tags]   Verify_Read_FRU_Data_Command

    Verify Read FRU Command Valid
    Verify Data Of FRU

*** Keywords ***

Verify Read FRU Command Valid
    [Documentation]  Verify read data FRU via IPMI Command valid or not

    # Run command fru list <fru ID>
    ${error}  ${data_fru}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  fru list ${FRU_ID}

    # Check command is valid
    Should Not Contain   ${data_fru}  Invalid command
    Should Not Contain   ${data_fru}  Unspecified error
    Set Test Variable  ${data_fru}

Verify Data Of FRU
    [Documentation]  Verify value of data respose

    # Verify data of chassis
    Verify Data Of Chassis
    # Verify data of board
    Verify Data Of Board
    # Verify data of product
    Verify Data Of Product

Verify Data Of Chassis
    [Documentation]  Verify value of chassis data respose

    ${ipmi_partNum}=  Get Lines Containing String
    ...  ${data_fru}  Chassis Part Number
    ${ipmi_partNum}=  Fetch From Right  ${ipmi_partNum}  :${SPACE}

    ${ipmi_seriNum}=  Get Lines Containing String
    ...  ${data_fru}  Chassis Serial
    ${ipmi_seriNum}=  Fetch From Right  ${ipmi_seriNum}  :${SPACE}

    ${fru_chassis}=  Read Properties  ${HOST_CHASSIS}

    Should Be Equal As Strings  ${ipmi_partNum}  ${fru_chassis["Part_Number"]}
    Should Be Equal As Strings  ${ipmi_seriNum}  ${fru_chassis["Serial_Number"]}

Verify Data Of Board
    [Documentation]  Verify value of board data respose

    ${ipmi_partNum}=  Get Lines Containing String
    ...  ${data_fru}  Board Part Number
    ${ipmi_partNum}=  Fetch From Right  ${ipmi_partNum}  :${SPACE}

    ${ipmi_seriNum}=  Get Lines Containing String
    ...  ${data_fru}  Board Serial
    ${ipmi_seriNum}=  Fetch From Right  ${ipmi_seriNum}  :${SPACE}

    ${ipmi_name}=  Get Lines Containing String  ${data_fru}  Board Product
    ${ipmi_name}=  Fetch From Right  ${ipmi_name}  :${SPACE}

    ${ipmi_mfg}=  Get Lines Containing String  ${data_fru}  Board Mfg
    ${ipmi_mfg}=  Fetch From Right  ${ipmi_mfg}  :${SPACE}

    ${fru_board}=  Read Properties  ${HOST_BOARD}

    Should Be Equal As Strings  ${ipmi_partNum}  ${fru_board["Part_Number"]}
    Should Be Equal As Strings  ${ipmi_seriNum}  ${fru_board["Serial_Number"]}
    Should Be Equal As Strings  ${ipmi_name}  ${fru_board["Name"]}
    Should Be Equal As Strings  ${ipmi_mfg}  ${fru_board["Manufacturer"]}

Verify Data Of Product
    [Documentation]  Verify value of product data respose

    ${ipmi_partNum}=  Get Lines Containing String
    ...  ${data_fru}  Product Part Number
    ${ipmi_partNum}=  Fetch From Right  ${ipmi_partNum}  :${SPACE}

    ${ipmi_seriNum}=  Get Lines Containing String
    ...  ${data_fru}  Product Serial
    ${ipmi_seriNum}=  Fetch From Right  ${ipmi_seriNum}  :${SPACE}

    ${ipmi_mfg}=  Get Lines Containing String  ${data_fru}  Product Manufacturer
    ${ipmi_mfg}=  Fetch From Right  ${ipmi_mfg}  :${SPACE}

    ${ipmi_ver}=  Get Lines Containing String  ${data_fru}  Product Version
    ${ipmi_ver}=  Fetch From Right  ${ipmi_ver}  :${SPACE}

    ${ipmi_name}=  Get Lines Containing String  ${data_fru}  Product Name
    ${ipmi_name}=  Fetch From Right  ${ipmi_name}  :${SPACE}

    ${fru_product}=  Read Properties  ${HOST_PRODUCT}

    Should Be Equal As Strings  ${ipmi_partNum}  ${fru_product["Model_Number"]}
    Should Be Equal As Strings  ${ipmi_seriNum}  ${fru_product["Serial_Number"]}
    Should Be Equal As Strings  ${ipmi_mfg}  ${fru_product["Manufacturer"]}
    Should Be Equal As Strings  ${ipmi_ver}  ${fru_product["Version"]}
    Should Be Equal As Strings  ${ipmi_name}  ${fru_product["Name"]}

Verify FRU Interface Exists On DBus
    [Documentation]  Verify FRU interface exists on D-Bus or not.

    # Check the FRU interface exist on D-Bus
    ${data_board}=  Read Properties  ${HOST_BOARD}
    Set Test Variable  ${data_board}

    # Check Chassis/Product area
    ${fru_chassis}=  Read Properties  ${HOST_CHASSIS}
    Set Test Variable  ${fru_chassis}

    ${fru_product}=  Read Properties  ${HOST_PRODUCT}
    Set Test Variable  ${fru_product}

    # Check Multirecord area
    ${fru_multi}=  Read Properties  ${HOST_MULTIRECORD}
    Set Test Variable  ${fru_multi}

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

Verify Value Of FRU Inventory Area Infor
    [Documentation]  Verify the value of command raw with fru_id

    #Run command raw ipmi, value return LS, MS, 0/1(Bytes/Words)
    ${resp}=  Run IPMI Standard Command  raw 0x0a 0x10 ${FRU_ID}
    Should Not Contain   ${resp}   Unable to send RAW command

    #Calculate size of fru
    ${size_board}=  Convert To Integer  ${data_board["Size"]}
    ${size_chassis}=  Convert To Integer  ${fru_chassis["Size"]}
    ${size_product}=  Convert To Integer  ${fru_product["Size"]}
    ${size_multi}=  Convert To Integer  ${fru_multi["Size"]}

    ${size}=  Evaluate
    ...  (${size_board}+${size_chassis}+${size_product}+${size_multi})

    ${size_lsb}=  Evaluate  ${size} & 0xFF
    ${size_lsb}=  Convert To Hex  ${size_lsb}  length=2
    ${size_msb}=  Evaluate  (${size} >> 8) & 0xFF
    ${size_msb}=  Convert To Hex  ${size_msb}  length=2

    Should Be Equal As Integers  ${resp}
    ...  ${size_lsb}${SPACE}${size_msb}${SPACE}${0}${0}

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
