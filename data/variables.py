import os

OPENBMC_BASE_URI = '/xyz/openbmc_project/'
OPENBMC_BASE_DBUS = 'xyz.openbmc_project.'

# org open power base URI.
OPENPOWER_BASE_URI = '/org/open_power/'
OPENPOWER_CONTROL = OPENPOWER_BASE_URI + 'control/'
OPENPOWER_SENSORS = OPENPOWER_BASE_URI + 'sensors/'

# REST URI base endpoint paths.
CONTROL_URI = OPENBMC_BASE_URI + 'control/'
# old vs new code dependencies in many places.
# TODO: remove when ready.
SETTINGS_URI = '/org/openbmc/settings/'
WATCHDOG_URI = OPENBMC_BASE_URI + 'watchdog/'
TIME_MANAGER_URI = OPENBMC_BASE_URI + 'time/'
NETWORK_MANAGER = OPENBMC_BASE_URI + 'network/'
# SNMP
SNMP_MANAGER_URI = NETWORK_MANAGER + 'snmp/manager/'
# Sensors base variables.
SENSORS_URI = OPENBMC_BASE_URI + 'sensors/'

# State Manager base variables
BMC_REBOOT_TRANS = 'xyz.openbmc_project.State.BMC.Transition.Reboot'

HOST_POWEROFF_TRANS = 'xyz.openbmc_project.State.Host.Transition.Off'
HOST_POWERON_TRANS = 'xyz.openbmc_project.State.Host.Transition.On'
HOST_REBOOT_TRANS = 'xyz.openbmc_project.State.Host.Transition.Reboot'
HOST_POWEROFF_STATE = 'xyz.openbmc_project.State.Host.HostState.Off'
HOST_POWERON_STATE = 'xyz.openbmc_project.State.Host.HostState.Running'

CHASSIS_POWEROFF_TRANS = 'xyz.openbmc_project.State.Chassis.Transition.Off'
CHASSIS_POWERON_TRANS = 'xyz.openbmc_project.State.Chassis.Transition.On'
CHASSIS_POWEROFF_STATE = 'xyz.openbmc_project.State.Chassis.PowerState.Off'
CHASSIS_POWERON_STATE = 'xyz.openbmc_project.State.Chassis.PowerState.On'

# State Manager URI variables.
SYSTEM_STATE_URI = OPENBMC_BASE_URI + 'state/'
BMC_STATE_URI = OPENBMC_BASE_URI + 'state/bmc0/'
HOST_STATE_URI = OPENBMC_BASE_URI + 'state/host0/'
CHASSIS_STATE_URI = OPENBMC_BASE_URI + 'state/chassis0/'
HOST_WATCHDOG_URI = OPENBMC_BASE_URI + 'watchdog/host0/'

# Logging URI variables
BMC_LOGGING_URI = OPENBMC_BASE_URI + 'logging/'
BMC_LOGGING_ENTRY = BMC_LOGGING_URI + 'entry/'

# Software manager version
SOFTWARE_VERSION_URI = OPENBMC_BASE_URI + 'software/'
ACTIVE = 'xyz.openbmc_project.Software.Activation.Activations.Active'
READY = 'xyz.openbmc_project.Software.Activation.Activations.Ready'
INVALID = 'xyz.openbmc_project.Software.Activation.Activations.Invalid'
ACTIVATING = 'xyz.openbmc_project.Software.Activation.Activations.Activating'
NOTREADY = 'xyz.openbmc_project.Software.Activation.Activations.NotReady'
FAILED = 'xyz.openbmc_project.Software.Activation.Activations.Failed'

SOFTWARE_ACTIVATION = 'xyz.openbmc_project.Software.Activation'
REQUESTED_ACTIVATION = SOFTWARE_ACTIVATION + '.RequestedActivations'
REQUESTED_ACTIVE = REQUESTED_ACTIVATION + '.Active'
REQUESTED_NONE = REQUESTED_ACTIVATION + '.None'

SOFTWARE_PURPOSE = 'xyz.openbmc_project.Software.Version.VersionPurpose'
VERSION_PURPOSE_HOST = SOFTWARE_PURPOSE + '.Host'
VERSION_PURPOSE_BMC = SOFTWARE_PURPOSE + '.BMC'
VERSION_PURPOSE_SYSTEM = SOFTWARE_PURPOSE + '.System'

# Software Host Inventory
SOFTWARE_HOST_INVENTORY_URI = SOFTWARE_VERSION_URI + 'host/inventory/'

# Image Upload Directory Path
IMAGE_UPLOAD_DIR_PATH = '/tmp/images/'

# Inventory URI
HOST_INVENTORY_URI = OPENBMC_BASE_URI + 'inventory/'

# Led URI variable
LED_GROUPS_URI = OPENBMC_BASE_URI + 'led/groups/'
LED_PHYSICAL_URI = OPENBMC_BASE_URI + 'led/physical/'

# Host control URI variables.
CONTROL_HOST_URI = OPENBMC_BASE_URI + 'control/host0/'

# Power restore variables.
POWER_RESTORE_URI = CONTROL_HOST_URI + 'power_restore_policy'
CONTROL_DBUS_BASE = 'xyz.openbmc_project.Control.'

RESTORE_LAST_STATE = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.Restore'
ALWAYS_POWER_ON = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.AlwaysOn'
ALWAYS_POWER_OFF = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.AlwaysOff'

# Dump URI variables.
DUMP_URI = OPENBMC_BASE_URI + '/dump/'
DUMP_ENTRY_URI = DUMP_URI + 'entry/'
# The path on the BMC where dumps are stored.
DUMP_DIR_PATH = "/var/lib/phosphor-debug-collector/dumps/"

# Boot progress variables.
STATE_DBUS_BASE = 'xyz.openbmc_project.State.'
OS_BOOT_START = STATE_DBUS_BASE + 'Boot.Progress.ProgressStages.OSStart'
OS_BOOT_OFF = STATE_DBUS_BASE + 'Boot.Progress.ProgressStages.Unspecified'
OS_BOOT_PCI = STATE_DBUS_BASE + 'Boot.Progress.ProgressStages.PCIInit'
OS_BOOT_SECPCI = STATE_DBUS_BASE + \
    'Boot.Progress.ProgressStages.SecondaryProcInit'
OS_BOOT_MEM = STATE_DBUS_BASE + 'Boot.Progress.ProgressStages.MemoryInit'
OS_BOOT_MOTHERBOARD = STATE_DBUS_BASE + \
    'Boot.Progress.ProgressStages.MotherboardInit'

# OperatingSystem status variables.
OS_BOOT_COMPLETE = STATE_DBUS_BASE + \
    'OperatingSystem.Status.OSStatus.BootComplete'
OS_BOOT_CDROM = STATE_DBUS_BASE + 'OperatingSystem.Status.OSStatus.CDROMBoot'
OS_BOOT_ROM = STATE_DBUS_BASE + 'OperatingSystem.Status.OSStatus.ROMBoot'
OS_BOOT_PXE = STATE_DBUS_BASE + 'OperatingSystem.Status.OSStatus.PXEBoot'
OS_BOOT_CBoot = STATE_DBUS_BASE + 'OperatingSystem.Status.OSStatus.CBoot'
OS_BOOT_DiagBoot = STATE_DBUS_BASE + 'OperatingSystem.Status.OSStatus.DiagBoot'

# Boot variables.
BOOT_SOURCE_DEFAULT = 'xyz.openbmc_project.Control.Boot.Source.Sources.Default'
BOOT_SOURCE_NETWORK = 'xyz.openbmc_project.Control.Boot.Source.Sources.Network'
BOOT_SOURCE_DISK = 'xyz.openbmc_project.Control.Boot.Source.Sources.Disk'
BOOT_SOURCE_CDROM = 'xyz.openbmc_project.Control.Boot.Source.Sources.ExternalMedia'
BOOT_MODE_SAFE = 'xyz.openbmc_project.Control.Boot.Mode.Modes.Safe'
BOOT_MODE_SETUP = 'xyz.openbmc_project.Control.Boot.Mode.Modes.Setup'
BOOT_MODE_REGULAR = 'xyz.openbmc_project.Control.Boot.Mode.Modes.Regular'

# Time variables.
TIME_DBUS_BASE = 'xyz.openbmc_project.Time.'
BMC_OWNER = TIME_DBUS_BASE + 'Owner.Owners.BMC'
HOST_OWNER = TIME_DBUS_BASE + 'Owner.Owners.Host'
SPLIT_OWNER = TIME_DBUS_BASE + 'Owner.Owners.Split'
BOTH_OWNER = TIME_DBUS_BASE + 'Owner.Owners.Both'
NTP_MODE = TIME_DBUS_BASE + 'Synchronization.Method.NTP'
MANUAL_MODE = TIME_DBUS_BASE + 'Synchronization.Method.Manual'

# User manager variable.
BMC_USER_URI = OPENBMC_BASE_URI + 'user/'

# The path on the BMC where signed keys are stored.
ACTIVATION_DIR_PATH = "/etc/activationdata/"

# Redfish variables.
REDFISH_BASE_URI = '/redfish/v1/'
REDFISH_SESSION = REDFISH_BASE_URI + 'SessionService/Sessions'
REDFISH_SESSION_URI = 'SessionService/Sessions/'

# rsyslog variables.
REMOTE_LOGGING_URI = OPENBMC_BASE_URI + 'logging/config/remote/'

'''
  QEMU HTTPS variable:

  By default lib/resource.txt AUTH URI construct is as
  ${AUTH_URI}   https://${OPENBMC_HOST}${AUTH_SUFFIX}
  ${AUTH_SUFFIX} is populated here by default EMPTY else
  the port from the OS environment
'''


def get_port_https():
    # defaulted to empty string
    l_suffix = ''
    try:
        l_https_port = os.getenv('HTTPS_PORT')
        if l_https_port:
            l_suffix = ':' + l_https_port
    except BaseException:
        print ("Environment variable HTTPS_PORT not set,\
              using default HTTPS port")
    return l_suffix


AUTH_SUFFIX = {
    "https_port": [get_port_https()],
}

# Update the ':Port number' to this variable
AUTH_SUFFIX = AUTH_SUFFIX['https_port'][0]

# Here contains a list of valid Properties bases on fru_type after a boot.
INVENTORY_ITEMS = {
    "CPU": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],

    "DIMM": [
        "Asset Tag",
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Model Number",
        "Name",
        "Serial Number",
        "Version",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "MEMORY_BUFFER": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "FAN": [
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "DAUGHTER_CARD": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "BMC": [
        "fault",
        "fru_type",
        "is_fru",
        "manufacturer",
        "present",
        "version",
    ],
    "MAIN_PLANAR": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "Part Number",
        "Serial Number",
        "Type",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "SYSTEM": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Model Number",
        "Name",
        "Serial Number",
        "Version",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "CORE": [
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
}

# These arrays are from DMTF bundle schema: DSP8010_2018.1 Redfish Schema Bundle
# ... which using for computer system test suite.

COMPUTER_SYSTEM_ITEMS = {
    "RESET_TYPE": [
        "On",
        "ForceOff",
        "ForceOn",
        "ForceRestart",
        "GracefulShutdown",
        "GracefulRestart",
        "Nmi",
        "PushPowerButton",
        "PowerCycle",
    ],
    "SYSTEM_TYPE": [
        "Physical",
        "Virtual",
        "OS",
        "PhysicallyPartitioned",
        "VirtuallyPartitioned",
        "Composed",
    ],
    "BOOT_SOURCE": [
        "None",
        "Pxe",
        "Floppy",
        "Cd",
        "Usb",
        "Hdd",
        "BiosSetup",
        "Utilities",
        "Diags",
        "UefiShell",
        "UefiTarget",
        "SDCard",
        "UefiHttp",
        "RemoteDrive",
        "UefiBootNext",
    ],
    "BOOT_ENABLED": [
        "Disabled",
        "Once",
        "Continuous",
    ],
    "BOOT_MODE": [
        "Legacy",
        "UEFI",
    ],
    "INDICATOR_LED": [
        "Unknown",
        "Lit",
        "Blinking",
        "Off",
    ],
    "POWER_STATE": [
        "On",
        "Off",
        "PoweringOn",
        "PoweringOff",
    ],
    "STATE": [
        "Enabled",
        "Disabled",
        "StandbyOffline",
        "StandbySpare",
        "InTest",
        "Starting",
        "Absent",
        "UnavailableOffline",
        "Deferring",
        "Quiesced",
        "Updating",
    ],
    "HEALTH": [
        "OK",
        "Warning",
        "Critical",
    ],
    "BOOTSOURCEOVERRIDEENABLED": [
        "Disabled",
        "Once",
        "Continuous",
    ],
}

# redfish log collection items from DSP8010_2018.1 Redfish Schema Bundle.
# Contain list status which got from redfish.
# For sensortype, entrycode, severity base LogEntry ver1.3.0
LOG_COLLECTION_ITEMS = {
    "OVERWRITEPOLICY": [
        "Unknown",
        "WrapsWhenFull",
        "NeverOverWrites",
    ],
    "STATE": [
        "Enabled",
        "Disabled",
        "StandbyOffline",
        "StandbySpare",
        "InTest",
        "Starting",
        "Absent",
        "UnavailableOffline",
        "Deferring",
        "Quiesced",
        "Updating",
    ],
    "HEALTH": [
        "OK",
        "Warning",
        "Critical",
    ],
    "SENSORTYPE": [
       "Platform Security Violation Attempt",
       "Temperature",
       "Voltage",
       "Current",
       "Fan",
       "Physical Chassis Security",
       "Processor",
       "Power Supply / Converter",
       "PowerUnit",
       "CoolingDevice",
       "Other Units-based Sensor",
       "Memory",
       "Drive Slot/Bay",
       "POST Memory Resize",
       "System Firmware Progress",
       "Event Logging Disabled",
       "System Event",
       "Critical Interrupt",
       "Button/Switch",
       "Module/Board",
       "Microcontroller/Coprocessor",
       "Add-in Card",
       "Chassis",
       "ChipSet",
       "Other FRU",
       "Cable/Interconnect",
       "Terminator",
       "SystemBoot/Restart",
       "Boot Error",
       "BaseOSBoot/InstallationStatus",
       "OS Stop/Shutdown",
       "Slot/Connector",
       "System ACPI PowerState",
       "Watchdog",
       "Platform Alert",
       "Entity Presence",
       "Monitor ASIC/IC",
       "LAN",
       "Management Subsystem Health",
       "Battery",
       "Session Audit",
       "Version Change",
       "FRUState",
       "OEM",
    ],
    "ENTRYCODE": [
        "Assert",
        "Deassert",
        "Lower Non-critical - going low",
        "Lower Non-critical - going high",
        "Lower Critical - going low",
        "Lower Critical - going high",
        "Lower Non-recoverable - going low",
        "Lower Non-recoverable - going high",
        "Upper Non-critical - going low",
        "Upper Non-critical - going high",
        "Upper Critical - going low",
        "Upper Critical - going high",
        "Upper Non-recoverable - going low",
        "Upper Non-recoverable - going high",
        "Transition to Idle",
        "Transition to Active",
        "Transition to Busy",
        "State Deasserted",
        "State Asserted",
        "Predictive Failure deasserted",
        "Predictive Failure asserted",
        "Limit Not Exceeded",
        "Limit Exceeded",
        "Performance Met",
        "Performance Lags",
        "Transition to OK",
        "Transition to Non-Critical from OK",
        "Transition to Critical from less severe",
        "Transition to Non-recoverable from less severe",
        "Transition to Non-Critical from more severe",
        "Transition to Critical from Non-recoverable",
        "Transition to Non-recoverable",
        "Monitor",
        "Informational",
        "Device Removed / Device Absent",
        "Device Inserted / Device Present",
        "Device Disabled",
        "Device Enabled",
        "Transition to Running",
        "Transition to In Test",
        "Transition to Power Off",
        "Transition to On Line",
        "Transition to Off Line",
        "Transition to Off Duty",
        "Transition to Degraded",
        "Transition to Power Save",
        "Install Error",
        "Fully Redundant",
        "Redundancy Lost",
        "Redundancy Degraded",
        "Non-redundant:Sufficient Resources from Redundant",
        "Non-redundant:Sufficient Resources from Insufficient Resources",
        "Non-redundant:Insufficient Resources",
        "Redundancy Degraded from Fully Redundant",
        "Redundancy Degraded from Non-redundant",
        "D0 Power State",
        "D1 Power State",
        "D2 Power State",
        "D3 Power State",
        "OEM",
    ],
    "SEVERITY": [
        "Emergency",
        "Alert",
        "Critical",
        "Error",
        "Warning",
        "Notice",
        "Informational",
        "Debug",
    ],
}

# redfish chassis items from DSP8010_2018.1 Redfish Schema Bundle.
# it is used for ocp redfish chassis test suite.

CHASSIS_ITEMS = {
    "CHASSIS_TYPE": [
        "Rack",
        "Blade",
        "Enclosure",
        "StandAlone",
        "RackMount",
        "Card",
        "Cartridge",
        "Row",
        "Pod",
        "Expansion",
        "Sidecar",
        "Zone",
        "Sled",
        "Shelf",
        "Drawer",
        "Module",
        "Component",
        "IPBasedDrive",
        "RackGroup",
        "StorageEnclosure",
        "Other"
    ],
    "STATE": [
        "Enabled",
        "Disabled",
        "StandbyOffline",
        "StandbySpare",
        "InTest",
        "Starting",
        "Absent",
        "UnavailableOffline",
        "Deferring",
        "Quiesced",
        "Updating",
    ],
    "HEALTH": [
        "OK",
        "Warning",
        "Critical",
    ],
}

MANAGER_BMC_ITEMS = {
    "RESET_TYPE": [
        "On",
        "ForceOff",
        "GracefulShutdown",
        "GracefulRestart",
        "ForceRestart",
        "Nmi",
        "ForceOn",
        "PushPowerButton",
        "PowerCycle",
    ],
    "MANAGER_TYPE": [
        "ManagementController",
        "EnclosureManager",
        "BMC",
        "RackManager",
        "AuxiliaryController",
        "Service",
    ],
    "POWER_STATE": [
        "On",
        "Off",
        "PoweringOn",
        "PoweringOff",
    ],
}
