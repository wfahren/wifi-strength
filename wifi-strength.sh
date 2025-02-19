#!/bin/sh
#
#File name: wifi-strength.bash
#Description: This script scans for "masters" and displays wifi signal strength
# with a text based bar graph.
#Version 1.1v 09/7/2020
#2020 Bill Fahrenkrug -  bill.fahrenkrug@gmail.com
#
# Script Dependency: B{ASH} like shell and iw. No other package requirements.
#
# The SSID and signal strength are from iw output, others are
# calculated like Quality and GOOD/BAD signal.
#
# As normal user:
#  sudo bash wifi-strength.sh -h
#  iw scan command requires root access

# Set Defaults
strenght_str='#'  # default pound sign
bar_len='50'      # default 50
bar_fill_char=' ' # default space
num_lines=''      # number of lines to display
scan=1            # scan for AP's

#must provide the network interface, wlan0 for example
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

    #for arg in "$@"; do
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
                shift
                shift
                ;;
            -l)
                if  echo "$2" | grep -qE "^[1-9][0-9]?$|^100$"; then bar_len="$2"; fi
                shift
                shift
                ;;
            *)
                echo -ne "\n\nInvalid option: $key\n\n"
                usage_txt
                ;;
        esac

        #Last arg is the network interface, required.
        #net=$arg

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
  -l\tLength of strength bar, range 1-100, Default 50
Example:
  Scan for \"masters\" on interface wlan1;

\t$script wlan1

  Scan AP's on wlan1 set strength bar length to 10;

\t$script -l 10 wlan1

  Monitor client connetion on interface wlan1

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

#  Parse the signal level, frequency and SSID from "iw dev scan".
clean_string() {
    local string="$1"
    echo "$string" | tr -d '\r\n' | sed 's/^[ \t]*//'
}

# Function to parse options from scan data
parse_scan() {
    data_freq=""
    data_signal=""
    data_ssid=""
    n=1

    # Read each line from the input (scan data)
    while IFS= read line; do
        # Clean the line
        line=$(clean_string "$line")
        # Parse based on key
        echo "$line" | grep -q "^BSS" && data_bssid=$(echo "$line" | grep -oE '[0-9a-fA-F:]{17}')
        echo "$line" | grep -q "^freq:" && data_freq=$(echo "$line" | awk '{print int($2)}')
        echo "$line" | grep -q "^signal:" && data_signal=$(echo "$line" | awk '{print int($2)}')
        echo "$line" | grep -q "^SSID:" && data_ssid=$(echo "$line" | cut -d' ' -f2-)

        # Handle case where SSID is missing, and set to <hidden>       
        [ -z "$data_ssid" ] && data_ssid="<hidden>"

        # If all four entries are present, append to results and reset
        if [ -n "$data_bssid" ] && [ -n "$data_freq" ] && [ -n "$data_signal" ] && [ -n "$data_ssid" ]; then
            printf "%s,%s,%s,%s\n" "$data_signal" "$data_freq" "$data_bssid" "$data_ssid" >> /tmp/results.$$
            data_bssid=""
            data_freq=""
            data_signal=""
            data_ssid=""
        fi
    done

    # Sort results by signal strength in descending order (numeric, reverse)
    # Use 'sort -rn' where -n is for numeric sort and -r is for reverse
    if [ -s /tmp/results.$$ ]; then
        sorted_results=$(sort -rn /tmp/results.$$)
        rm -f /tmp/results.$$

        # Process and print sorted results
        echo "$sorted_results" | while IFS=',' read s f bs ss; do

            # Truncate SSID if longer than 30 characters
            ss_len=$(echo -n "$ss" | wc -c)
            [ "$ss_len" -gt 30 ] && ss=$(echo -n "$ss" | head -c 26)

            # Print the output if all fields are present
            if [ "$num_lines" ] && [ "$n" -gt "$num_lines" ]; then break; fi
            [ -n "$s" ] && [ -n "$f" ] && get_output "$s" "$ss" "$f" "$bs"
            # uncomment to test scan parse only
            # [ -n "$s" ] && [ -n "$f" ] && echo "signal: $s, freq: $f, SSID: $ss"
            
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

# Take the signal strength $rssi calculate quality based on below from OpenWRt
# iwinfo source with -40 dBm 100% and -110 0%.
#
# GOOD/BAD link quality is based on research, but can easily be change below.
#

# From openWRT source iwinfo command:
#
#----------------------------------------------------------------------------------#
##$iwinfo_nl80211.c-2595-            /* Quality */
##iwinfo_nl80211.c-2596-          if (rssi < 0)
##iwinfo_nl80211.c-2597-          {
##iwinfo_nl80211.c-2598-              /* The cfg80211 wext compat layer assumes a signal range
##iwinfo_nl80211.c:2599:               * of -110 dBm to -40 dBm, the quality value is derived
##iwinfo_nl80211.c-2600-               * by adding 110 to the signal level */
##iwinfo_nl80211.c:2601:              if (rssi < -110)
##iwinfo_nl80211.c:2602:                  rssi = -110;
##iwinfo_nl80211.c-2603-              else if (rssi > -40)
##iwinfo_nl80211.c-2604-                  rssi = -40;
##iwinfo_nl80211.c-2605-
##iwinfo_nl80211.c-2606-              e->quality = (rssi + 110);
##iwinfo_nl80211.c-2607-          }
##iwinfo_nl80211.c-2608-          else
##iwinfo_nl80211.c-2609-          {
##iwinfo_nl80211.c-2610-              e->quality = rssi;
##iwinfo_nl80211.c-2611-          }
#---------------------------------------------------------------------------------#

# Calculate quality and range from Strong to Bad. Format the output for
# display.
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
        siginal='-110'
    elif [ "$rssi" -gt -40 ]; then
        siginal='-40'
    else
        siginal=$rssi
    fi

    if [ "$rssi" = 0 ]; then
        link=''
        bw=''
        quality=''
    else
        quality=$(((siginal + 110) * 10 / 7)) # Quality as percentage max -40 min -110
        get_strength_bar "$strenght_str" "$quality" "$bar_len"
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

#main


if [ $# = 1 ] && [ ! "$1" = '-h' ]; then
    net=$1
else
    parse_options "$@"
fi

# Loop until ctrl-C
while true; do

    if [ "$scan" = 1 ]; then
        echo -ne "\nScanning on $net.................\n"
        echo -ne "\nPress ctrl-c to quit\n"
        scan_data=$(iw dev "$net" scan lowpri passive 2>/dev/null || echo $?) 
        sleep 5 # give time for scan to complete
        if [ ${#scan_data} -gt 3 ]; then
            scan_data=$(echo "$scan_data" | grep  -E 'freq:|signal:|SSID:|^BSS' )
        elif [ "$scan_data" -eq "255" ]; then
            echo -ne "\n\n\tMust be root to run\n"\
            "\tEither change to user root or use sudo\n\n"
            break
        else
            echo -ne "\n\n\tWireless interface busy trying again in 5 seconds\n\n"
            sleep 5
            continue
         fi
        clear
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
