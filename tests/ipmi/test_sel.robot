*** Settings ***
Documentation  Test IPMI SEL.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot

*** Variables ***

${SEL_SRC_FILE}       ./tests/ipmi/sel_src.txt

*** Test Cases ***

Verify Adding SEL with IPMI
    [Documentation]  Verify adding new system event log (SEL) into BMC
    ...              by using IPMI sel add command
    [Tags]  Verify_Adding_SEL_with_IPMI

    ${resp}=  Run External IPMI Standard Command  sel clear
    Should Not Contain  ${resp}    Invalid command

    # The source data of following error sources:
    # event 1. Temperature #0x30 Upper Critical going high
    # event 2. Voltage #0x3b Lower Critical going low
    # event 3. System Event #0x00 Timestamp Clock Sync
    ${resp}=  Run External IPMI Standard Command  sel add ${SEL_SRC_FILE}
    Should Not Contain  ${resp}    Invalid command

    ${resp}=  Run External IPMI Standard Command  sel list
    Check SEL Log  ${resp}  Temperature #0x30  Upper Critical going high  Asserted
    Check SEL Log  ${resp}  Voltage #0x3b  Lower Critical going low  Asserted
    Check SEL Log  ${resp}  System Event  Timestamp Clock Sync  Asserted

Verify Adding Sample Event with IPMI
    [Documentation]  Verify adding sample event into BMC
    ...              by using IPMI event 1/2/3 commands
    [Tags]  Verify_Adding_Sample_Event_with_IPMI

    ${resp}=  Run External IPMI Standard Command  sel clear
    Should Not Contain  ${resp}    Invalid command

    # The source data of following error sources:
    # event 1. Temperature #0x30 | Upper Critical going high | Asserted
    # event 2. Voltage #0x60 | Lower Critical going low  | Asserted
    # event 3. Memory #0x53 | Correctable ECC | Asserted
    ${resp}=  Run External IPMI Standard Command  event 1
    Should Not Contain  ${resp}    Invalid command

    ${resp}=  Run External IPMI Standard Command  event 2
    Should Not Contain  ${resp}    Invalid command

    ${resp}=  Run External IPMI Standard Command  event 3
    Should Not Contain  ${resp}    Invalid command

    ${resp}=  Run External IPMI Standard Command  sel list
    Check SEL Log  ${resp}  Temperature #0x30  Upper Critical going high  Asserted
    Check SEL Log  ${resp}  Voltage #0x60  Lower Critical going low  Asserted
    Check SEL Log  ${resp}  Memory #0x53  Correctable ECC  Asserted


*** Keywords ***

Check SEL Log
    [Arguments]  ${msg}  ${expect_str_1}  ${expect_str_2}  ${expect_str_3}
    [Documentation]  Check if the message contains the list of expected
    ...              strings

    Should Contain  ${msg}  ${expect_str_1}
    Should Contain  ${msg}  ${expect_str_2}
    Should Contain  ${msg}  ${expect_str_3}
