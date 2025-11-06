# AppDaemon Copilot Instructions

This document provides essential knowledge for AI coding agents to be productive in this AppDaemon codebase.

## 1. Project Overview

This is an AppDaemon project for Home Assistant, designed to run Python apps that automate various aspects of a smart home. The core functionality revolves around interacting with Home Assistant entities and services. This application is created under a Linux 5.x kernel 64-bit OS. The system is pre-installed with Python version 3.12.11.

The primary app, `printer_api.py`, discovers network printers by scanning the local subnet for devices with an open printer port (9100). It then uses the external `snmpget` command-line tool to query device information and ink levels, which are published to a Home Assistant sensor.

## 2. Architecture and Data Flow

- **AppDaemon Core:** The `appdaemon.yaml` file configures the AppDaemon instance, including Home Assistant connection details, app directory, and other settings.
- **Apps:** Python files in the `apps/` directory (e.g., `printer_api.py`) contain the logic for automations. Each app is defined in `apps/apps.yaml`.
- **Home Assistant Integration:** Apps interact with Home Assistant via the `appdaemon.plugins.hass.hassapi` library. This allows apps to listen for events, get/set states of entities, and call services.
- **Network Scanning:** The `printer_api.py` app uses Python's `concurrent.futures.ThreadPoolExecutor` to perform an efficient, non-blocking scan of the local network.
- **Threading:** To avoid blocking the main AppDaemon event loop, network scans are launched in a separate background thread using Python's standard `threading` module. A `threading.Lock` is used to prevent multiple scans from running simultaneously.

## 3. Key Files and Directories

- `appdaemon.yaml`: Main AppDaemon configuration.
- `requirements.txt`: Project-wide Python dependencies (if any). Note that this project relies on the `snmpget` command-line tool, which must be installed separately on the system.
- `apps/`: Contains individual AppDaemon applications.
    - `apps/apps.yaml`: Defines and configures the AppDaemon apps.
    - `apps/printer_api.py`: The main app for discovering and monitoring network printers.
- `dashboards/`: Contains HADashboard configurations.

## 4. Developer Workflows

### 4.1. AppDaemon App Development

1.  **Create/Modify App:** Write Python code in a new or existing file within the `apps/` directory (e.g., `apps/my_new_app.py`).
2.  **Configure App:** Add an entry for your app in `apps/apps.yaml`, specifying the `module` (filename without `.py`) and `class` name.
    ```yaml
    my_printer_app:
      module: printer_api
      class: PrinterMonitor
    ```
3.  **Register Services (if applicable):** If your app exposes services to Home Assistant, register them in the `initialize` method using `self.register_service()`.
    ```python
    # In your app's initialize method
    self.register_service("my_domain/my_service", self.my_service_callback)
    ```
4.  **Restart AppDaemon:** After making changes to app code or configuration, AppDaemon usually reloads apps automatically. If not, a full restart of the AppDaemon add-on might be necessary.

### 4.2. Dependency Management

- **Python Packages:** List any required Python packages in `requirements.txt`.
- **System-level Dependencies:** This project requires the `net-snmp` package (or equivalent) to be installed on the host system to provide the `snmpget` command. This is a system-level dependency, not a Python package, and must be installed via the OS package manager (e.g., `apk add net-snmp` on Alpine, `apt-get install snmp` on Debian).

## 5. Project-Specific Conventions

- **AppDaemon Class Structure:** All AppDaemon apps inherit from `hass.Hass` and implement an `initialize` method for setup.
- **Logging:** Use `self.log()` for general logging. For more detailed or separated logging, a dedicated `logging.Logger` instance with a `RotatingFileHandler` is used, as seen in `printer_api.py`.
- **Background Tasks:** For long-running or blocking tasks like network scans, use Python's standard `threading` module to run them in a background thread. This is critical to avoid making the AppDaemon core unresponsive. Use a `threading.Lock` to prevent race conditions if the task can be triggered from multiple sources (e.g., a schedule and a service call).

## 6. Example: `printer_api.py`

The `printer_api.py` app demonstrates a robust pattern for network scanning in AppDaemon:
- **Initialization:** A `threading.Lock` is created to ensure only one scan runs at a time. A daily scan is scheduled with `self.run_every()`.
- **Non-Blocking Scans:** Service calls and scheduled callbacks do not perform the scan directly. Instead, they start the `scan_printers` method in a new background thread.
- **Concurrent Port Scanning:** It uses a `ThreadPoolExecutor` to efficiently check for open printer ports across the entire subnet without waiting for each IP to time out sequentially.
- **External Commands:** It calls the `snmpget` command-line tool using `subprocess.run` to query printer details.

```python
# apps/printer_api.py
import appdaemon.plugins.hass.hassapi as hass
import subprocess
import threading
import concurrent.futures
import socket

class PrinterMonitor(hass.Hass):
    def initialize(self):
        # A lock to ensure that only one scan runs at a time.
        self.scan_lock = threading.Lock()
        self.log("PrinterMonitor service is initializing.")
        
        # Schedule the scan to run daily.
        self.run_every(self.scan_printers_scheduled_callback, "now", 86400)

    def scan_printers_scheduled_callback(self, kwargs):
        """Callback for the scheduled scan."""
        self.log("Scheduled printer scan initiated.")
        # Run the actual scan in a background thread to avoid blocking.
        scan_thread = threading.Thread(target=self.scan_printers, daemon=True)
        scan_thread.start()

    def scan_printers(self, **kwargs):
        """
        Scans the network for printers concurrently.
        """
        if self.scan_lock.locked():
            self.log("Scan already in progress.")
            return

        with self.scan_lock:
            self.log("Starting network scan...")
            with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
                # ... logic to submit port scan tasks to the executor ...
                pass
            # ... logic to process results and update Home Assistant ...
            self.log("Network scan complete.")

    def _snmp_query(self, ip, oid):
        """
        Executes an external `snmpget` command.
        """
        try:
            command = ['snmpget', '-v', '2c', '-c', 'public', ip, oid]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=3
            )
            # ... parsing logic ...
            return parsed_value
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return None
```
