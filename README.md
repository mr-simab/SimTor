# SimTor : Wireless Network Deauthentication Simulator

SimTor is an automated wireless security testing script that handles WiFi scanning, MAC address randomization, and multi‑terminal deauthentication for educational and penetration testing purposes.

-------------------------------------------------------------------------------

LEGAL DISCLAIMER    
Use this tool only on networks you own or have explicit written permission to test.
Unauthorized WiFi attacks are illegal. The author is not responsible for misuse.

-------------------------------------------------------------------------------

FEATURES
- Auto-detects wireless adapter
- Auto-renames adapter to "simtor"
- Auto-enables monitor mode
- WiFi scanning using airodump-ng
- Parsed list of detected networks
- Network selection menu
- Auto channel setting
- MAC address randomizer (rotates every 3 minutes)
- Multi-terminal deauthentication (5 senders)
- Master controller terminal (Q = Quit, N = Select another network)
- Safe cleanup of all terminals and processes
- Recursive re-selection of networks

-------------------------------------------------------------------------------

REQUIREMENTS

Operating System:
- Kali Linux or any Debian-based distribution

Auto-installed packages:
- aircrack-ng
- macchanger
- figlet
- xterm
- aireplay-ng
- airodump-ng

Hardware:
- A WiFi adapter that supports Monitor Mode and Packet Injection

-------------------------------------------------------------------------------

INSTALLATION

git clone https://github.com/mr-simab/SimTor.git
cd SimTor
chmod +x simtor.sh

-------------------------------------------------------------------------------

USAGE

sudo ./simtor.sh

-------------------------------------------------------------------------------

Workflow Overview

1. Initial Setup
   - Displays header
   - Checks root permissions
   - Installs missing packages

2. Wireless Adapter Detection
   - Automatically detects a wireless card
   - Exits safely if none found

3. Adapter Renaming and Monitor Mode
   - Renames interface to "simtor"
   - Enables monitor mode using airmon-ng

4. Network Scanning
   - Opens an airodump-ng window
   - User presses Q to stop scanning

5. Network Selection
   - Shows cleaned list of networks
   - User selects an index

6. MAC Randomizer
   - Separate terminal randomizes MAC every 180 seconds

7. Multi-Terminal Deauthentication
   - Launches 5 xterm windows sending continuous deauth packets

8. Main Controller Window
   - Q = Quit all terminals and exit the script
   - N = Return to network selection (recursive retry)

9. Cleanup
   - Kills sender terminals
   - Kills MAC randomizer
   - Returns to selection or fully exits

-------------------------------------------------------------------------------

FILE STRUCTURE

SimTor/     
 ├── simtor.sh      
 └── README.md

-------------------------------------------------------------------------------
AUTHOR

SimTor Script by: MrSima
For improvements, suggestions, or contributions, feel free to open an issue or pull request.

-------------------------------------------------------------------------------
