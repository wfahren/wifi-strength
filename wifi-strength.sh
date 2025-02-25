#!/bin/sh
#
# File name: wifi-strength.sh
# Description: This script scans for "masters" and displays wifi signal strength
# with a text-based bar graph.
# Version 1.1v 09/7/2020
# 2020 Bill Fahrenkrug - bill.fahrenkrug@gmail.com
#
# Script Dependency: BASH-like shell and iw. No other package requirements.
#
# The SSID and signal strength are from iw output, others are
# calculated like Quality and GOOD/BAD signal.
#
# As normal user:
#  sudo bash wifi-strength.sh -h
#  iw scan command requires root access

# Set Defaults
strength_str='#'  # default pound sign
bar_len='50'      # default 50
bar_fill_char=' ' # default space
num_lines=''      # number of lines to display
scan=1            # scan for AP's
passive=1        # scan type, default active scan
scan_interval='5' # scan interval, default 5 seconds

# Must provide the network interface, wlan0 for example
if [ $# -lt 1 ]; then
    echo -ne "
 Usage: \"$(basename -- "$0") [options] [interface]\"
 -- for example; 
\t$(basename -- "$0") wlan1\t# scan wlan1
\t$(basename -- "$0") -h\t# for help
\n Interfaces found:
"
    iw dev 2> /dev/null | grep "Interface" | awk '{print $2}'
    exit
fi

# Parse command line options and ignore invalid.
parse_options() {
    while [ $# -gt 1 ]; do
        key="$1"
        case "$key" in
            -h)
                usage_txt
                ;;
            -m)
                scan=0
                shift
                ;;
            -n)
                num_lines="$2"
                shift 2
                ;;
            -i)
                scan_interval="$2"
                shift 2
                ;;
            -l)
                if echo "$2" | grep -qE "^[1-9][0-9]?$|^100$"; then bar_len="$2"; fi
                shift 2
                ;;
            -a)
                passive=0
                shift
                ;;
            -f)
                filter="$2"
                shift 2
                ;;
            *)
                echo -ne "\n\nInvalid option: $key\n\n"
                usage_txt
                ;;
        esac
    done
    net="${1:-}"
}

# Help text
usage_txt() {
    script=$(basename -- "$0")
    echo -ne "
Usage: $script [options] <interface>

<interface>  The interface to monitor. 

[options]
  -m\tMonitor link signal strength.
  -n\tDisplay x number of lines
  -i\tSet scan interval, default 5 seconds
  -l\tLength of strength bar, range 1-100, Default 50
  -a\tActive scan, default passive scan. (Active scan sends Beacon's)
  -f\tFilter results, use extended grep pattern. Example: -f 'Whispering|MESH'
Example:
  Scan for \"masters\" on interface wlan1;

\t$script wlan1

  Scan AP's on wlan1 set strength bar length to 10;

\t$script -l 10 wlan1

  Monitor client connection on interface wlan1

\t$script -m wlan1

\nInterfaces found:
"
    iw dev 2> /dev/null | grep "Interface" | awk '{print $2}'
    echo -ne "\n\n"
    exit
}

# Create $len length signal bar from percentage of $quality.
get_strength_bar() {
    char=$1
    fill_char=$bar_fill_char
    num=$2
    len=$3
    # Calculate number of char(s) for strength part of bar
    num_char=$(awk "BEGIN {printf \"%.0f\", $num/100*$len}")
    # Calculate number of char(s) to fill the remaining part of the bar.
    num_fill=$((len - num_char))
    v=$(printf "%${num_char}s" "")
    s=$(printf "%${num_fill}s" "")
    # Combine strength and fill char(s) to assign $strength
    strength=${v// /$char}${s// /$fill_char}
}

# Clean string by removing carriage returns and leading/trailing spaces
clean_string() {
    local string="$1"
    echo "$string" | tr -d '\r\n' | sed 's/^[ \t]*//'
}

# Function to parse options from scan data
check_complete() {
            # If no SSID or Mesh ID but other fields are set, assume hidden and finalize
            if [ -n "$data_bssid" ] && [ -n "$data_freq" ] && [ -n "$data_signal" ] && [ -n "$data_ssid" ]; then
                printf "%s,%s,%s,%s\n" "$data_signal" "$data_freq" "$data_bssid" "$data_ssid" >> /tmp/results.$$
                # Reset variables
                data_freq=""
                data_signal=""
                data_ssid=""
                # If new BSSID is set, set it to the current BSSID
                if [ -n "$new_bssid" ]; then
                    data_bssid="$new_bssid"
                    new_bssid=""
                else
                    data_bssid=""
                fi
            fi
        
}
# Function to parse options from scan data
parse_scan() {
    data_freq=""
    data_signal=""
    data_ssid=""
    data_bssid=""
    n=1

    # Read each line from the input (scan data)
    while IFS= read -r line; do
        # Clean the line
        line=$(clean_string "$line")

        # Skip empty lines
        [ -z "$line" ] && continue

        # Parse based on key. BSSI, freq, signal are mandatory keys.
        if [ -z "$data_bssid" ]; then
            echo "$line" | grep -q "^BSS" && data_bssid=$(echo "$line" | grep -oE '[0-9a-fA-F:]{17}')
            [ -n "$data_bssid" ] && continue
        fi

        if [ -z "$data_freq" ]; then
            echo "$line" | grep -q "^freq:" && data_freq=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+' | head -n1)
            [ -n "$data_freq" ] && continue
        fi

        if [ -z "$data_signal" ]; then
            echo "$line" | grep -q "^signal:" && data_signal=$(echo "$line" | awk '{print int($2)}')
            [ -n "$data_signal" ] && continue
        fi

        # After the three mandatory keys have been parsed, 
        # Check the line to see if a new station, if so we save.
        if echo "$line" | grep -q "^BSS" && check_bssid=$(echo "$line" | grep -oE '[0-9a-fA-F:]{17}'); then
            new_bssid="$check_bssid"
        fi
        # Now we need to set the SSID
        # If the line contains "SSID:" or "MESH ID:" then set the SSID to that.
        if echo "$line" | grep -q "MESH ID:"; then
            data_ssid=$(echo "$line" | awk '{print "MESH ID: " $3}')
            check_complete
        elif echo "$line" | grep -q "^SSID:"; then
            data_ssid=$(echo "$line" | cut -d' ' -f2-)
            check_complete
        # Default to hidden if no SSID or MESH ID is found.
        else
            data_ssid="<hidden>"
            check_complete
        fi
    done
 
    # Sort results by signal strength in descending order (numeric, reverse)
    if [ -s /tmp/results.$$ ]; then
        # Filter results if filter is set
        [ -n "$filter" ] && filtered_results=$(grep -Ei "$filter" /tmp/results.$$)
        [ -n "$filtered_results" ] && echo "$filtered_results" > /tmp/results.$$
        # Sort results
        sorted_results=$(sort -rn /tmp/results.$$ && echo "")
        rm -f /tmp/results.$$

        # Process and print sorted results
        echo "$sorted_results" | while IFS=',' read -r s f bs ss; do
            # Truncate SSID if longer than 30 characters
            ss_len=$(echo -n "$ss" | wc -c)
            [ "$ss_len" -gt 30 ] && ss=$(echo -n "$ss" | head -c 26)

            # Print the output if all fields are present
            if [ "$num_lines" ] && [ "$n" -gt "$num_lines" ]; then break; fi
            [ -n "$s" ] && [ -n "$f" ] && get_output "$s" "$ss" "$f" "$bs"
            n=$((n + 1))
        done
    fi
}

# Header for monitor link.
get_header() {
    echo -ne "Press ctrl-c to quit\n\n"
    iw dev "$net" link 2> /dev/null | awk 'FNR <= 3'
    header="\n%-"$((bar_len + 10))"s|%8s |%8s | %-10s\n"
    printf "$header" "" "Signal" "Quality" "Bandwidth"
}

# Calculate quality and range from Strong to Bad. Format the output for display.
get_output() {
    rssi=$1
    ssid=$2
    freq=$3
    bssid=$4

    if [ -z "$rssi" ] || [ "$rssi" -ge 0 ]; then
        strength='No signal'
    elif [ "$rssi" -ge -65 ]; then
        link='Strong'
    elif [ "$rssi" -ge -73 ]; then
        link='Good'
    elif [ "$rssi" -ge -80 ]; then
        link='Fair'
    elif [ "$rssi" -ge -94 ]; then
        link='Weak'
    else
        link='Bad'
    fi

    if [ "$rssi" -lt -110 ]; then
        signal='-110'
    elif [ "$rssi" -gt -40 ]; then
        signal='-40'
    else
        signal=$rssi
    fi

    if [ "$rssi" = 0 ]; then
        link=''
        bw=''
        quality=''
    else
        quality=$(((signal + 110) * 10 / 7)) # Quality as percentage max -40 min -110
        get_strength_bar "$strength_str" "$quality" "$bar_len"
    fi

    if [ "$scan" = 0 ]; then
        bw=$(iw "$net" link 2> /dev/null | grep "tx bitrate:" | awk '{print $3,$4}')
        format="[%-${bar_len}s] %6s |%8s |%7s%% | %-15s\r"
        printf "$format" "$strength" "$link" "$rssi" "$quality" "$bw"
    else
        format="[%-${bar_len}s] %6s |%5s |%7s%% |%10s | %s | %-15s\n"
        printf "$format" "$strength" "$link" "$rssi" "$quality" "$freq" "$bssid" "$ssid"
    fi
}

# Main
if [ $# = 1 ] && [ ! "$1" = "-h" ]; then
    net=$1
elif [ "$1" = "-h" ]; then
    usage_txt
else
    parse_options "$@"
fi

# Check that interface is valid
if ! iw dev 2> /dev/null | grep -q "Interface $net"; then
    echo -ne "\n\tInterface $net not found\n\n"
    exit
fi

# Loop until ctrl-C
while true; do
    if [ "$scan" = 1 ]; then
        
        echo -ne "\nPress ctrl-c to quit\n"
        echo -ne "Scanning on $net.................\n"

        if [ $passive -eq 1 ]; then
            # If passive scan is set, passive (don't send Beacon's) scan for AP's
            echo -ne "Passive scan\n"
            scan_data=$(iw dev "$net" scan passive 2>/dev/null && printf "\nExitCode: %03d\n" $? || printf "\nExitCode: %03d\n" $?) 
        else
            # If passive scan is not set, active scan for AP's
            echo -ne "Active scan\n"
            scan_data=$(iw dev "$net" scan 2>/dev/null && printf "\nExitCode: %03d\n" $? || printf "\nExitCode: %03d\n" $?)
        fi

        # The "$scan_interval" # allows time for scan to complete and we don't want to overload the interface
        # never should be less than 5 seconds. 
        sleep "$scan_interval"
        
        # Get the exit code for the scan data, it will be on the last line
        exit_code=$(echo "$scan_data" | tail -n 1 | awk '{print $2}')
        # echo -ne "\n\nExit code:   ""$exit_code""\n\n"
        # If the exit code is 0, the scan data is valid
        if [ "$exit_code" -eq "0" ]; then
            scan_data=$(echo "$scan_data" | grep -E '^BSS|freq:|signal:|SSID:|MESH ID')
        # If the exit code is 255, the user must be root to run the script
        elif [ "$exit_code" -eq "255" ]; then
            scan_data=$(echo "$scan_data" | grep -v "ExitCode")
            echo -ne "\n\n\tMust be root to run\n"\
            "\tEither change to user root or use sudo\n\n"
            break
            # If the exit code is 237, the wireless interface not found
        elif [ "$exit_code" -eq "237" ]; then
            scan_data=$(echo "$scan_data" | grep -v "ExitCode")
            echo -ne "\n\tInterface device ""$net"" not connected.\n\n"
            break
            # If the exit code is 1, the iw command returned an error
        elif [ "$exit_code" -eq "1" ]; then
            scan_data=$(echo "$scan_data" | grep -v "ExitCode")  
            echo -ne "\n\n\tiw command failed, or error returned from the iw command\n\n"          
            break
        else
            # If the exit code is not 0, 255, or 1, the wireless interface is busy
            scan_data=$(echo "$scan_data" | grep -v "ExitCode")
            echo -ne "\n\n\tWireless interface busy trying again in 5 seconds\n\n"
            sleep 5
            continue
        fi
        clear
        # echo -ne "\n\n""$exit_code""\n\n"
        header="\n%"$((bar_len + 9))"s |%5s |%8s |%10s | %-17s | %-10s\n"
        printf "$header" "Signal" "dBm" "Quality" "Frequency" "BSSID" "SSID"
        # Parse the scan data
        echo "$scan_data" | parse_scan
    else
        rssi=$(iw dev "$net" link | grep signal || echo $?)
        if [ "$rssi" != "1" ]; then
            clear
            get_header
            get_output "$(echo "$rssi" | awk '{print $2}')"
            sleep 2
        else
            echo -ne "\n\Interface device ""$net"" not connected.\n"
            break
        fi
    fi
done

exit