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

    Create Session  openbmc  ${AUTH_URI}  timeout=${timeout}
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
