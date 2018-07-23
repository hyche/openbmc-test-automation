*** Settings ***
Library  OperatingSystem

*** Variables ***

*** Keywords ***
Parse Json From File
    [Documentation]    Read expected JSON file then convert to JSON object.
    [Arguments]  ${json_file_path}

    # Description of argument(s):
    # json_file_path    Path of target json file

    OperatingSystem.File Should Exist  ${json_file_path}
    ${file}=          OperatingSystem.Get File  ${json_file_path}
    ${json}=          To JSON  ${file}
    [Return]          ${json}

Verify Redfish Fixed Entries
    [Documentation]  Verify all the fixed entries got from GET request to
    ...  bmcweb are correct (Based on DSP2049).
    [Arguments]  ${test_entries}  ${json_file_path}

    # Description of argument(s):
    # json_file_path    Path of target json file

    ${expected_json}=  Parse Json From File  ${json_file_path}
    Dictionary Should Contain Sub Dictionary  ${test_entries}  ${expected_json}
    ...  msg=Entries not match from expected JSON
