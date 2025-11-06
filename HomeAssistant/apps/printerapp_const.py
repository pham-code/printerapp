# Constants for the PrinterMonitor AppDaemon app.

# --- Network Configuration ---
SCAN_INTERVAL_SECONDS = 86400  # 24 hours
PRINTER_PORT = 9100
NETWORK_PREFIX = "192.168.1."
IP_RANGE_START = 1
IP_RANGE_END = 255
MAX_SCAN_WORKERS = 50
PORT_OPEN_TIMEOUT = 1
SNMP_TIMEOUT = 2

# --- Home Assistant Configuration ---
PRINTER_SENSOR_ENTITY_ID = "sensor.network_printers"

# --- SNMP Configuration ---
# Standard SNMP OIDs
OID_SYS_DESCR = '1.3.6.1.2.1.1.1.0'

# Brother-specific SNMP OIDs
OID_BROTHER_MODEL_INFO = '1.3.6.1.4.1.2435.2.3.9.1.1.7.0'
BROTHER_MODEL_KEY = 'MDL'

# OIDs for Brother ink levels (integer format)
BROTHER_INTEGER_OIDS = {
    'Black':   '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.10.1',
    'Cyan':    '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.11.1',
    'Magenta': '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.12.1',
    'Yellow':  '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.13.1',
}

# OIDs for Brother ink levels (hex format)
BROTHER_HEX_OIDS = {
    'Black':   '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.8.0',
    'Cyan':    '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.9.0',
    'Magenta': '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.10.0',
    'Yellow':  '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.11.0',
}

# --- Device Information ---
PRINTER_MAKES = ["Brother", "HP", "Epson", "Canon"]
INK_COLORS = ['Black', 'Cyan', 'Magenta', 'Yellow']

# --- Parsing Constants ---
# Markers for parsing Brother ink level hex strings
HEX_MARKER_DIRECT_PERCENTAGE = '81'
HEX_MARKER_MAX_LEVEL = ['00', '01', '04']
HEX_MARKER_CURRENT_LEVEL = ['08', '01', '04']
