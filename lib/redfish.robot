*** Settings ***
Library  OperatingSystem
Library  String

*** Variables ***

*** Keywords ***
Redfish Patch Request
    [Documentation]  Do REST PATCH request and return the result. Same
    ...  functionality with OpenBMC request but different authentication.
    # Example result data:
    # <Response [200]>
    [Arguments]    ${uri}    ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Patch Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Create Session  redfish  ${AUTH_URI}  timeout=${timeout}  max_retries=3
    ...  auth=@{credentials}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=     Create Dictionary   Content-Type=application/json
    set to dictionary   ${kwargs}       headers     ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Patch
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Patch Request  redfish  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Delete All Sessions
    [Return]    ${ret}

Find Property Index In List Of Dictionaries
    [Documentation]  Find the index of a property in list of dicts.
    ...  Return the found index if found, otherwise return the length
    ...  of the list.
    [Arguments]  ${key}  ${value}  @{list}

    # Description of argument(s):
    # key           The key whose index need to be found.
    # value         The value of key to be compared.
    # list          List of dictionaries
    #               eg: [{...}, {...}, ...]

    ${index}=  Set Variable  ${0}
    :FOR  ${dict}  IN  @{list}
    \  ${found_value}=  Get From Dictionary  ${dict}  ${key}
    \  Exit For Loop If  '${value}' == '${found_value}'
    \  ${index}=  Set Variable  ${index + 1}

    [Return]  ${index}

Redfish Get Property
    [Documentation]  Extract property from JSON payload which is retrieved by
    ...  GET request.
    [Arguments]  ${uri}  ${property}  ${timeout}=10  ${quiet}=${QUIET}
    # Description of argument(s):
    # uri               URI of the resource contains the property.
    # property          Name of the property.
    # timeout           Timeout for the REST call.
    # quiet             If enabled, turns off logging to console.

    Should Be String  ${property}
    ${resp}=  OpenBMC Get Request  ${uri}  timeout=${timeout}  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  To Json  ${resp.content}
    [Return]  ${content['${property}']}

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
