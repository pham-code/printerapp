import appdaemon.plugins.hass.hassapi as hass
import subprocess
import socket
import threading
import concurrent.futures
import printerapp_const as const

class PrinterScanner(hass.Hass):
    """
    An AppDaemon application that discovers network printers and monitors their
    ink levels using the Simple Network Management Protocol (SNMP).

    The app scans the local network for devices with an open printer port (9100),
    queries them for identity and ink information, and publishes the findings
    to a Home Assistant sensor (`sensor.network_printers`).

    Features:
    - Daily automatic network scans.
    - On-demand scanning via a Home Assistant service call.
    - Concurrent scanning for efficiency, without blocking AppDaemon's main thread.
    - A lock to prevent multiple scans from running simultaneously.
    - Specific support for parsing ink levels from Brother printers.
    """

    def initialize(self):
        """
        Initializes the AppDaemon app.

        This method sets up the scan lock, registers the service for on-demand
        scans, and schedules the daily automatic scan.
        """
        # A lock to ensure that only one scan runs at a time.
        self.scan_lock = threading.Lock()

        self.log("PrinterScanner service is initializing.")

        # Register a service for on-demand printer scans.
        self.register_service("printer_api/scan_printers", self.scan_printers_service_callback)

        # Schedule the scan to run daily, starting now.
        self.run_every(self.scan_printers_scheduled_callback, "now", const.SCAN_INTERVAL_SECONDS)
        self.log("Printer scan scheduled to run once a day.")

    def scan_printers_service_callback(self, namespace, service, data):
        """
        Handles the service call from Home Assistant to trigger a printer scan.
        """
        self.log("Received service call to scan printers.")
        # Start the scan in a background thread to avoid blocking AppDaemon.
        scan_thread = threading.Thread(target=self.scan_printers, kwargs={}, daemon=True)
        scan_thread.name = "printer_service_scan"
        scan_thread.start()

    def scan_printers_scheduled_callback(self, kwargs):
        """
        Handles the scheduled (daily) call to trigger a printer scan.
        """
        self.log("Scheduled printer scan initiated.")
        # Start the scan in a background thread to avoid blocking AppDaemon.
        scan_thread = threading.Thread(target=self.scan_printers, kwargs=kwargs or {}, daemon=True)
        scan_thread.name = "printer_scheduled_scan"
        scan_thread.start()

    def scan_printers(self, **kwargs):
        """
        Scans the local network for printers and updates their status in Home Assistant.

        This method uses a thread pool to concurrently check for open printer
        ports (9100) across the 192.168.1.x subnet. For each discovered printer,
        it fetches detailed information and ink levels.
        """
        if self.scan_lock.locked():
            self.log("Scan already in progress, skipping this run.")
            return

        with self.scan_lock:
            discovered_printers = []
            
            self.log(f"Starting network scan for printers in subnet {const.NETWORK_PREFIX}0/24.")

            # Use a ThreadPoolExecutor to perform concurrent port scans.
            with concurrent.futures.ThreadPoolExecutor(max_workers=const.MAX_SCAN_WORKERS) as executor:
                # Create a dictionary mapping future tasks to their corresponding IP addresses.
                future_to_ip = {
                    executor.submit(self._is_port_open, f"{const.NETWORK_PREFIX}{i}", const.PRINTER_PORT): f"{const.NETWORK_PREFIX}{i}"
                    for i in range(const.IP_RANGE_START, const.IP_RANGE_END)
                }
                
                # Process the results as they are completed.
                for future in concurrent.futures.as_completed(future_to_ip):
                    ip_address = future_to_ip[future]
                    try:
                        # If the port is open, the device is likely a printer.
                        if future.result():
                            self.log(f"Found open printer port on {ip_address}. Getting details.")
                            printer_info = self.get_printer_info(ip_address)
                            
                            # Proceed only if we could identify the printer's make.
                            if printer_info and printer_info.get("make"):
                                cartridge_levels = self.get_cartridge_levels(ip_address, printer_info)
                                printer_info["cartridges"] = cartridge_levels
                                discovered_printers.append(printer_info)
                                self.log(f"Successfully collected data for: {printer_info['make']} {printer_info['model']} at {ip_address}.")
                            else:
                                self.log(f"Could not retrieve sufficient info for device at {ip_address}.", level="DEBUG")
                    except Exception as exc:
                        self.log(f"An error occurred while processing IP {ip_address}: {exc}", level="ERROR")

            # Update the Home Assistant sensor with the scan results.
            if discovered_printers:
                self.log(f"Scan complete. Found {len(discovered_printers)} printer(s): {discovered_printers}")
                self.set_state(const.PRINTER_SENSOR_ENTITY_ID, state=len(discovered_printers), attributes={"printers": discovered_printers})
            else:
                self.log("Scan complete. No printers found on the network.")
                self.set_state(const.PRINTER_SENSOR_ENTITY_ID, state=0, attributes={"printers": []})
            
            self.log("Network scan complete.")
        
    def _is_port_open(self, ip, port, timeout=const.PORT_OPEN_TIMEOUT):
        """
        Checks if a TCP port is open on a given IP address.

        Args:
            ip (str): The IP address to check.
            port (int): The port number to check.
            timeout (int): The connection timeout in seconds.

        Returns:
            bool: True if the port is open, False otherwise.
        """
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(timeout)
                s.connect((ip, port))
            return True
        except (socket.timeout, ConnectionRefusedError):
            return False
        except Exception as e:
            self.log(f"Error checking port {port} on {ip}: {e}", level="DEBUG")
            return False

    def get_printer_info(self, ip_address):
        """
        Retrieves the make and model of a printer using SNMP.

        It first attempts to identify the make from the system description.
        Then, it queries a specific OID known to contain detailed model info
        for Brother printers. As a fallback, it attempts to parse the model
        from the system description.

        Args:
            ip_address (str): The IP address of the printer.

        Returns:
            dict: A dictionary containing printer details.
        """
        printer_details = {
            "ip_address": ip_address,
            "make": None,
            "model": None,
            "description": None,
        }

        # 1. Get the system description to infer the manufacturer.
        sys_descr_oid = const.OID_SYS_DESCR
        description = self._snmp_query(ip_address, sys_descr_oid)
        
        if description:
            printer_details["description"] = description
            desc_lower = description.lower()
            
            for make in const.PRINTER_MAKES:
                if make.lower() in desc_lower:
                    printer_details["make"] = make
                    break

        # 2. For Brother printers, query a specific OID for the exact model name.
        #    The result is a semicolon-separated string, e.g., "MDL:MFC-L2750DW;"
        model_oid = const.OID_BROTHER_MODEL_INFO
        model_string = self._snmp_query(ip_address, model_oid)
        if model_string:
            try:
                pairs = model_string.split(';')
                for pair in pairs:
                    if ':' in pair:
                        key, value = pair.split(':', 1)
                        if key.strip().upper() == const.BROTHER_MODEL_KEY:
                            printer_details["model"] = value.strip()
                            break  # Stop after finding the model
            except Exception as e:
                self.log(f"Could not parse model string '{model_string}': {e}", level="ERROR")

        # 3. As a fallback, attempt to parse the model from the system description.
        if not printer_details["model"] and description:
            try:
                # Often, the model is the first part of the description string.
                model_part = description.split(',')[0]
                make = printer_details.get("make")
                if make:
                    # Remove the make from the string to get a cleaner model name.
                    parsed_model = model_part.lower().replace(make.lower(), "").strip()
                    printer_details["model"] = parsed_model.upper()
                else:
                    printer_details["model"] = model_part.strip()
            except Exception as e:
                self.log(f"Could not parse model from description '{description}': {e}", level="WARNING")

        return printer_details

    def get_cartridge_levels(self, ip_address, printer_info):
        """
        Retrieves ink cartridge levels for a given printer.

        Currently, this method specifically supports Brother printers by using a
        hybrid strategy:
        1. It first tries OIDs that return a direct integer value.
        2. If that fails, it falls back to OIDs that return a complex
           hexadecimal string, which is then parsed.

        Args:
            ip_address (str): The IP address of the printer.
            printer_info (dict): A dictionary of printer details, including the make.

        Returns:
            list: A list of dictionaries, each representing an ink cartridge.
        """
        cartridge_info = []
        
        if printer_info.get("make") == "Brother":
            # OIDs that are known to return a direct integer (e.g., page count).
            integer_oids = {
                'Black':   '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.10.1',
                'Cyan':    '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.11.1',
                'Magenta': '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.12.1',
                'Yellow':  '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.1.1.13.1',
            }
            
            # OIDs that are known to return a complex hex string requiring parsing.
            hex_oids = {
                'Black':   '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.8.0',
                'Cyan':    '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.9.0',
                'Magenta': '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.10.0',
                'Yellow':  '1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.11.0',
            }

            for color in ['Black', 'Cyan', 'Magenta', 'Yellow']:
                level_display = "N/A"
                
                # First, attempt to get the level from an integer-based OID.
                level_int = self._snmp_query(ip_address, integer_oids[color])
                if level_int and level_int.isdigit():
                    level_display = f"{level_int}%"
                else:
                    # If the integer OID fails, fall back to the hex-based OID.
                    level_hex = self._snmp_query(ip_address, hex_oids[color])
                    if level_hex:
                        level_display = self._parse_brother_ink_level(level_hex)

                cartridge_info.append({
                    "name": f"{color} Ink Cartridge",
                    "level": level_display,
                    "color": color.lower()
                })

        return cartridge_info

    def _parse_brother_ink_level(self, hex_string):
        """
        Parses complex hexadecimal strings from Brother printers to find the ink level.
        """
        if not hex_string or not isinstance(hex_string, str) or hex_string == '""':
            return "N/A"

        try:
            parts = hex_string.replace('\n', ' ').strip().split()
            if not parts:
                return "N/A"
            
            # Format 1: Direct percentage (marker '81')
            if '81' in parts:
                idx = parts.index('81')
                if idx + 6 < len(parts):
                    hex_val = "".join(parts[idx+3:idx+7])
                    level = int(hex_val, 16)
                    return f"{level}%"
            
            # Format 2: Max and current levels (markers '00 01 04' and '08 01 04')
            try:
                max_marker_start = -1
                for i in range(len(parts) - 2):
                    if parts[i:i+3] == ['00', '01', '04']:
                        max_marker_start = i
                        break
                
                curr_marker_start = -1
                for i in range(len(parts) - 2):
                    if parts[i:i+3] == ['08', '01', '04']:
                        curr_marker_start = i
                        break

                if max_marker_start != -1 and curr_marker_start != -1:
                    if max_marker_start + 6 < len(parts) and curr_marker_start + 6 < len(parts):
                        hex_max = "".join(parts[max_marker_start+3:max_marker_start+7])
                        hex_curr = "".join(parts[curr_marker_start+3:curr_marker_start+7])
                        
                        val_max = int(hex_max, 16)
                        val_curr = int(hex_curr, 16)

                        if val_max > 0:
                            percent = round((val_curr / val_max) * 100)
                            return f"{percent}%"
            except (ValueError, IndexError):
                pass

            return "Unknown Format"

        except (ValueError, IndexError) as e:
            self.log(f"Could not parse Brother hex string '{hex_string}': {e}", level="ERROR")
            return "Parse Error"

    def _snmp_query(self, ip, oid, timeout=const.SNMP_TIMEOUT):
        """
        Executes an external `snmpget` command to query a device.

        Args:
            ip (str): The IP address of the target device.
            oid (str): The SNMP Object Identifier (OID) to query.
            timeout (int): The timeout for the command in seconds.

        Returns:
            str or None: The value returned from the device, or None if the
                         query fails or returns no valid data.
        """
        try:
            command = ['snmpget', '-v', '2c', '-c', 'public', '-t', str(timeout), ip, str(oid)]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=timeout + 1  # subprocess timeout should be slightly longer
            )
            output = result.stdout.strip()

            # The command may succeed but return no value.
            if 'No Such Instance' in output or 'No Such Object' in output:
                return None

            # The output format is typically "OID = TYPE: Value".
            if '=' in output:
                value_part = output.split('=', 1)[1].strip()
                # The value itself may have a type prefix, e.g., "STRING: \"Value\"".
                if ':' in value_part:
                    return value_part.split(':', 1)[1].strip().strip('"')
                return value_part
            
            return None
        except FileNotFoundError:
            self.log("`snmpget` command not found. Please ensure the `net-snmp` package is installed.", level="ERROR")
            return None
        except subprocess.CalledProcessError as e:
            # This occurs if snmpget returns a non-zero exit code.
            self.log(f"snmpget command failed for {ip} (OID: {oid}): {e.stderr}", level="WARNING")
            return None
        except subprocess.TimeoutExpired:
            self.log(f"snmpget command timed out for {ip} (OID: {oid}).", level="WARNING")
            return None
        except Exception as e:
            self.log(f"An unexpected error occurred during snmpget query for {ip} (OID: {oid}): {e}", level="ERROR")
            return None