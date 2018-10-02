*** Settings ***

Documentation  Install RHEL OS and run an HTX bootme.

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS Host user name.
#   OS_PASSWORD                 The OS Host password.
#   FTP_USERNAME                The FTP username.
#   FTP_PASSWORD                The FTP password.
#   OS_REPO_URL                 The URL for the OS to be installed.
#                               (e.g "ftp.com/redhat/RHEL/Server/os/").
#   Optional Parameters:
#     HTX_DURATION              The duration of the HTX run (e.g 2h,3m)
#                               Defaults to 2h.
#     HTX_INTERVAL              The time delay between checks of HTX
#                               status, defaults to 10m.
#     HTX_LOOPS                 The number of times to loop through
#                               htx, defualts to 2.
#     DEBUG                     If this is set, extra debug information
#                               will be printed out, defaults to 1.

Resource             ../syslib/utils_install.robot

Suite Teardown  Collect HTX Log Files

*** Variables ***
${HTX_DURATION}      2h
${HTX_INTERVAL}      10m
${HTX_LOOPS}         2
${DEBUG}             1


*** Test Cases ***
OS Install
    [Documentation]  Install the given OS through the network.
    [Tags]  OS_Install

    ${cmd}=  Catenate  sol_utils.tcl --os_host=${OS_HOST}
    ...  --os_password=${OS_PASSWORD} --os_username=${OS_USERNAME}
    ...  --openbmc_host=${OPENBMC_HOST}
    ...  --openbmc_password=${OPENBMC_PASSWORD}
    ...  --openbmc_username=${OPENBMC_USERNAME}
    ...  --proc_name=install_os  --debug=${DEBUG}
    ...  --ftp_username=${FTP_USERNAME}  --ftp_password=${FTP_PASSWORD}
    ...  --os_repo_url=${os_repo_url}
    ${rc}  ${out_buf}=  Cmd Fnc  ${cmd}


 Configure Yum Repository For FTP3
    [Documentation]  Configure Yum repository for ftp3 server on pegas.
    ...  This is needed for HTX to be installed.
    [Tags]  Configure_Yum_Repository_For_FTP3

    ${cmd}=  Catenate
     ...  printf "[pegas-ga-ftp3-server]\nname=pegas-ga-ftp3-server
     ...  \nbaseurl=ftp://${FTP_USERNAME}:${FTP_PASSWORD}@${OS_REPO_URL}
     ...  \nenabled=1\ngpgcheck=0"  > /etc/yum.repos.d/pegas_ga.repo
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  yum update
    Should Be Empty  ${stderr}
    ...  msg=Yum update returned an error. Verify ftp credentials.


Install HTX And Run Bootme
    [Documentation]  Install HTX and start extended bootme run.
    [Tags]  Install_HTX_And_Run_Bootme

    Install HTX On RedHat  ${htx_rpm}
    Login To OS
    Repeat Keyword  ${HTX_LOOPS} times  Run Keywords
    ...  Run MDT Profile
    ...  AND  Repeat Keyword  ${HTX_DURATION}
    ...  Check HTX Run Status  ${HTX_INTERVAL}
    ...  AND  Shutdown HTX Exerciser
