*** Settings ***
Documentation  Test Ampere Computing GPI sensors.

Resource               ../lib/rest_client.robot
Library                ../data/variables.py
Resource               ../lib/utils.robot

*** Variables ***


*** Test Cases ***

Verify Ampere Computing GPI Sensors
    [Documentation]  Verify that list of Ampere Computing GPI sensors
    ...              are present
    [Tags]  Verify_Ampere_Computing_GPI_Sensors
    @{gpi_list_nodes} =  Create List
    # List of exported GPI sensors
    ...  GPI_CTRL_0
    ...  GPI_CTRL_1
    ...  GPI_CTRL_2
    ...  GPI_CTRL_3
    ...  GPI_DATA_SET
    ...  GPI_DATA_SET_0
    ...  GPI_DATA_SET_1
    ...  GPI_DATA_SET_2
    ...  GPI_DATA_SET_3
    ...  VRD_HOT_ERR
    ...  DIMM_HOT_ERR
    ...  L3C_ERR
    ...  PCIE_ERR
    ...  MCU_ERR
    ...  SATA_ERR
    ...  PMD_ERR_SET_0
    ...  PMD_ERR_SET_1
    ...  BOOT_1_ERR
    ...  BOOT_2_ERR
    ...  WATHDOG_STATUS
    ...  RAS_INT_ERR

    :FOR  ${gpi_node}  IN  @{gpi_list_nodes}
    \  Check GPI Sensor Node  ${gpi_node}

*** Keywords ***

Check GPI Sensor Node
    [Documentation]  Check the present of GPI sensor.
    [Arguments]  ${gpi_node}
    # Description of arguments:
    # gpi_node  name of GPI sensor
    #           Example: "GPI_CTRL_0" is the endpoint for url
    #           /xyz/openbmc_project/sensors/gpi/
    ${resp}=  OpenBMC Get Request  ${OPENBMC_BASE_URI}sensors/gpi/${gpi_node}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Cannot find GPI sensor

