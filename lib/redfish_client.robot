*** Settings ***
Library           Collections
Library           String
Library           RequestsLibrary.RequestsKeywords
Library           OperatingSystem
Resource          resource.txt
Library           disable_warning_urllib.py
Resource          rest_response_code.robot

*** Variables ***

# Assign default value to QUIET for programs which may not define it.
${QUIET}          ${0}

*** Keywords ***

Redfish Login Request
    [Documentation]  Do REST login and return authorization token.
    [Arguments]  ${openbmc_username}=${OPENBMC_USERNAME}
    ...          ${openbmc_password}=${OPENBMC_PASSWORD}
    ...          ${alias_session}=openbmc
    ...          ${timeout}=20

    # Description of argument(s):
    # openbmc_username  The username to be used to login to the BMC.
    #                   This defaults to global ${OPENBMC_USERNAME}.
    # openbmc_password  The password to be used to login to the BMC.
    #                   This defaults to global ${OPENBMC_PASSWORD}.
    # alias_session     Session object name.
    #                   This defaults to "openbmc"
    # timeout           REST login attempt time out.

    Create Session  openbmc  ${REDFISH_AUTH_URI}  timeout=${timeout}
    ${headers}=  Create Dictionary  Content-Type=application/json

    ${data}=  Create Dictionary
    ...  UserName=${openbmc_username}  Password=${openbmc_password}

    ${resp}=  Post Request  openbmc
    ...  ${REDFISH_SESSION}  data=${data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content} =  To JSON  ${resp.content}

    Log  ${content["Id"]}
    Log  ${resp.headers["X-Auth-Token"]}

    [Return]  ${content["Id"]}  ${resp.headers["X-Auth-Token"]}


Redfish Get Request
    [Documentation]  Do REST GET request and return the result.
    [Arguments]  ${uri_suffix}
    ...          ${session_id}=${None}
    ...          ${xauth_token}=${None}
    ...          ${response_format}="json"
    ...          ${timeout}=30

    # Description of argument(s):
    # uri_suffix       The URI to establish connection with
    #                  (e.g. 'Systems').
    # session_id       Session id.
    # xauth_token      Authentication token.
    # response_format  The format desired for data returned by this keyword
    #                  (json/HTTPS response).
    # timeout          Timeout in seconds to establish connection with URI.

    ${base_uri} =  Catenate  SEPARATOR=  ${REDFISH_BASE_URI}  ${uri_suffix}

    # Create session, token list [vIP8IxCQlQ, Nq9l7fgP8FFeFg3QgCpr].
    ${id_auth_list} =  Create List  ${session_id}  ${xauth_token}

    # Set session and auth token variable.
    ${session_id}  ${xauth_token} =
    ...  Run Keyword If  "${xauth_token}" == "${None}"
    ...    Redfish Login Request
    ...  ELSE
    ...    Set Variable  ${id_auth_list}

    # Example: "X-Auth-Token: 3la1JUf1vY4yN2dNOwun"
    ${headers} =  Create Dictionary  Content-Type=application/json
    ...  X-Auth-Token=${xauth_token}

    ${resp}=  Get Request
    ...  openbmc  ${base_uri}  headers=${headers}  timeout=${timeout}

    Return From Keyword If  ${response_format} != "json"  ${resp}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    ${content} =  To JSON  ${resp.content}
    [Return]  ${content}


Redfish Delete Request
    [Documentation]  Delete the resource identified by the URI.
    [Arguments]  ${uri_suffix}
    ...          ${xauth_token}
    ...          ${timeout}=10

    # Description of argument(s):
    # uri_suffix   The URI to establish connection with
    #             (e.g. 'SessionService/Sessions/XIApcw39QU').
    # xauth_token  Authentication token.
    # timeout      Timeout in seconds to establish connection with URI.

    ${base_uri} =  Catenate  SEPARATOR=  ${REDFISH_BASE_URI}  ${uri_suffix}

    # Example: "X-Auth-Token: 3la1JUf1vY4yN2dNOwun"
    ${headers} =  Create Dictionary  Content-Type=application/json
    ...  X-Auth-Token=${xauth_token}

    # Delete server session.
    ${resp}=  Delete Request  openbmc
    ...  ${base_uri}  headers=${headers}  timeout=${timeout}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Delete client sessions.
    Delete All Sessions


Redfish Patch Request
    [Documentation]  Do REST PATCH request and return the result. Same
    ...  functionality with OpenBMC request but different authentication.
    # Example result data:
    # <Response [200]>
    [Arguments]    ${uri_suffix}  ${session_id}=${None}  ${xauth_token}=${None}
    ...            ${timeout}=10  &{kwargs}
    # Description of argument(s):
    # uri_suffix      The URI to establish connection with (e.g. 'Systems').
    # session_id      Session id.
    # xauth_token     Authentication token.
    # timeout         Timeout in seconds to establish connection with URI.
    # kwargs          Any additional arguments to be passed directly to the
    #                 Patch Request call. For example, the caller might
    #                 set kwargs as follows:
    #                 ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    ${session_id}  ${xauth_token}=  Run Keyword If  ${xauth_token} == ${None}
    ...  Redfish Login Request

    ${base_uri}=  Catenate  SEPARATOR=  ${REDFISH_BASE_URI}  ${uri_suffix}
    ${headers}=     Create Dictionary   Content-Type=application/json
    ...  X-Auth-Token=${xauth_token}
    Set To Dictionary   ${kwargs}       headers     ${headers}
    ${resp}=  Patch Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Delete All Sessions
    [Return]   ${resp}


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
    [Arguments]  ${uri_suffix}  ${property}
    # Description of argument(s):
    # uri_suffix        The URI to establish connection with (e.g. 'Systems').
    # property          Name of the property.
    # timeout           Timeout for the REST call.

    Should Be String  ${property}
    ${content}=  Redfish Get Request  ${uri_suffix}
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
