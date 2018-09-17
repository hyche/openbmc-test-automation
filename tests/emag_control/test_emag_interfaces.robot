*** Settings ***
Documentation     Verify E-MAG property.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.txt
Resource          ../../lib/utils.robot
Library           Collections
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify Host Memory Interface
    [Documentation]  Verify properties Host Memory interface
    [Tags]  Verify_Host_Memory_Interface

    Verify The Interface Exists

    Verify Host Memory Data From The Interface

Verify Host Boot Interface
    [Documentation]  Verify properties Host Boot interface
    [Tags]  Verify_Host_Boot_Interface

    Verify The Interface Exists

    Verify Host Boot Data From The Interface


*** Keywords ***

Verify The Interface Exists
    [Documentation]  Verify interface exist or not

    #Check interface exists or not
    ${data_inf}=  Read Properties  ${SOFTWARE_VERSION_URI}host/inventory
    Set Test Variable  ${data_inf}

Verify Host Memory Data From The Interface
    [Documentation]  Verify host memory data from interface

    #Read data from interface compare with expected
    ${expected_health}=  Get Computer System Items Schema  HEALTH
    ${expected_state}=  Get Computer System Items Schema   STATE

    ${data_health}=  Create List  ${data_inf["Health"]}
    List Should Contain Sub List  ${expected_health}  ${data_health}

    ${data_state}=  Create List  ${data_inf["State"]}
    List Should Contain Sub List  ${expected_state}  ${data_state}

    # Verify in range 1:1024 GB
    # TODO: adjust the valid range for other platform. The current platform
    # support 1:1024 GB only.
    ${data_mem}=  Convert To Integer  ${data_inf["TotalSystemMemoryGiB"]}
    Run Keyword If  ${data_mem} > 1024 or ${data_mem} < 1
    ...  Fail  msg=Value of TotalSystemMemoryGiB out of range

Verify Host Boot Data From The Interface
    [Documentation]  Verify host boot data from interface

    #Read data from interface compare with expected
    ${expected_boot_src_override}=  Get Computer System Items Schema
    ...  BOOTSOURCEOVERRIDEENABLED
    ${expected_boot_src_target}=  Get Computer System Items Schema
    ...  BOOT_SOURCE

    ${boot_src_override}=  Create List  ${data_inf["BootSourceOverrideEnabled"]}
    List Should Contain Sub List  ${expected_boot_src_override}
    ...  ${boot_src_override}

    ${boot_src_target}=  Create List  ${data_inf["BootSourceOverrideTarget"]}
    List Should Contain Sub List  ${expected_boot_src_target}
    ...   ${boot_src_target}
