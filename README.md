# ANRS
A fast and efficient network port scanner written in Bash. This command-line tool enables TCP and UDP port scanning with multiple scanning options for network reconnaissance.

## Features
🔍 TCP and UDP port scanning.
🚀 Single port, port range, and common ports scanning options.
⚡  Fast and efficient scanning with timeout controls.
📊 Progress indicators for long-running scans.
🛡️ Input validation and error handling.
🎨 Colored output for better readability.

## Installation
# Clone the repository
git clone https://github.com/PranitMarathe1311/ANRS.git

# Navigate to the project directory
cd ANRS

# Make the script executable
chmod +x scanner.sh

# Run the scanner
sudo ./scanner.sh

## Usage
The tool provides an interactive menu with the following options:

# TCP Scan
  1.Single port scan
  2.Port range scan
  3.Common ports scan
  
# UDP Scan
  1.Single port scan
  2.Common UDP ports scan

## Dependencies
This tool requires:
- netcat (nc) - for port scanning.
  [apt-get install netcat]
- telnet - for additional connection testing.
  [apt-get install telnet]
- bash (version 4.0 or higher).
- root/sudo privileges.
