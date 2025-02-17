#!/bin/bash
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
sort_data=0       # sort scan results best signal to worst
num_lines=''

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

    for arg in $@; do

        case "$arg" in
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
                ;;
            -f)
                force=1
                shift
                ;;
            -s)
                sort_data=1
                shift
                ;;
            -l)
                if [ $(echo $2 | grep  -E '^[1-9][0-9]?$|^100$') ]; then bar_len="$2"; fi
                shift
                ;;
            *)
                shift
                ;;
        esac

        #Last arg is the network interface, required.
        net=$arg

    done

}

# Help text
usage_txt() {

    script=$(basename -- "$0")
    echo -ne "
Usage: $script [options] <interface>

<interface>  The interface to monitor. 

[options]
  -m\tMonitor link signal strength.
  -s\tSort scan results.
  -n\tDisplay x number of lines
  -f\tForce monitoring even if interface does not exist.
  -l\tLength of strength bar, range 1-100, Default 50
Example:
  Scan for \"masters\" on interface wlan1;

\t$script wlan1

  Scan for \"masters\" on wlan1 set strength bar length to 80 
  and sort SSID's strongest to weakest signal;

\t$script -l 80 -s wlan1

  Monitor with bar graph on interface wlan1

\t$script -l 75 -m wlan1

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

# Every second check to make sure we are still connected when monitoring.
check_interface() {
    local n=0
    local msg_len=''
    local msg=''
    local format=''
    local t=0

    while [ ! "$(iw dev "$net" link 2> /dev/null | grep -e 'Connected')" ]; do
        n=1
        msg=' Waiting to connect'
        msg_len=${#msg}
        msg_len=$((bar_len - msg_len))
        if [ -z "$t" ] || [ "$t" = 0 ]; then
            get_strength_bar '*' '100' "$msg_len"
            t=1
        else
            get_strength_bar ' ' '100' "$msg_len"
            t=0
        fi
        format="%-${bar_len}s %-45s\r"
        printf "$format" "$msg$strength" ""
        sleep 1
    done

    if [ "$n" = 1 ]; then get_header; fi
}

#  Parse the signal level, frequency and SSID from "iw dev scan".
parse_scan() {
    local n=1
    local args=''
    local line=''
    local freq=''
    local rssi=''
    local ssid=''

    for args in "$@"; do
        case "$args" in
            freq:)
                freq=$2
                shift
                ;;
            signal:)
                rssi=$(printf %.0f "$2")
                shift
                ;;
            SSID:)
                ssid=$2
                if [ -z "$ssid" ] || [ "$ssid" = "freq:" ]; then
                    ssid="*empty"
                elif [ ${#2} -gt 30 ]; then
                    ssid="${ssid:0:26}..."
                fi
                # If sorting by signal strength save the station
                # info in $line{n} variable for sorting else print it.
                if [ "$sort_data" = 1 ] && [ "$resort" = 0 ]; then
                    #escape octel strings
                    ssid=${ssid//\x/\\x}
                    line="$rssi $freq $ssid"
                    eval "line${n}='$line'"
                else
                    if [ "$num_lines" ] && [ "$n" -gt "$num_lines" ]; then break; fi
                    get_output "$rssi" "$ssid" "$freq"
                fi

                n=$((n + 1))
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # If sorting send to data_sort with $n number of stations.
    if [ "$sort_data" = 1 ] && [ "$resort" = 0 ]; then
        data_sort "$n"
    else
        resort=0
    fi
}

# Take $line{n} variables sort
# and reformat for parsing again.
data_sort() {
    local n=$1
    local output=''
    local sort_items=''

    while [ "$n" -gt 1 ]; do
        n=$((n - 1))
        output=$output$(eval "echo \${line$n}'\n'")
    done

    sort_items=$(echo -ne "$output" | sort -rn)

    reformat $sort_items

    resort=1
    parse_scan $data
}

# Re-format the station data to be sent back through the
# "parse_scan" function sorted by signal strength.
reformat() {
    local i
    data=''

    for i in "$@"; do
        data="$data signal: $1 freq: $2 SSID: $3"
        shift 3
        if [ ! "$1" ]; then break; fi
    done
}

# Header for monitor link.
get_header() {
    echo -ne "Press q to quit\n\n"
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
        format="[%-${bar_len}s] %6s |%5s |%7s%% |%10s | %-15s\n"
        printf "$format" "$strength" "$link" "$rssi" "$quality" "$freq" "$ssid"
    fi
}

#main
force=0
scan=1
resort=0

if [ $# = 1 ] && [ ! "$1" = '-h' ]; then
    net=$1
else
    parse_options "$@"
fi

if [ "$force" != 1 ] && [ ! "$(iw dev 2> /dev/null | grep  -E "Inter.+($net$)" | awk '{print $2}')" ]; then
    echo -ne "\nNetwork interface not found.\nUse -f option to force\n\n"
    net=''
    exit
fi

if [ "$scan" = 0 ]; then
    clear
    get_header
    check_interface
fi

# Loop until ctrl-C
while true; do
    read -r -s -N 1 -t 1 key

    if [ "$key" = q ]; then
        echo ""
        break
    fi

    if [ "$scan" = 1 ]; then
        echo -ne "\nScanning on $net.................\n"
        echo -ne "\nPress q to quit\n"
        scan_data=$(iw dev "$net" scan passive 2>/dev/null | grep  -E 'freq:|signal:|SSID:')
        sleep 5 # give time for scan to complete
        if [ "$scan_data" = "" ]; then
            iw dev "$net" scan passive 2>/dev/null && exit_code=$? || exit_code=$?
            if [ "$exit_code" = 255 ]; then
                echo -ne "\n\n\tMust be root to run\n"\
                "\tEither change to user root or use sudo\n\n"
                break
            else
                echo -ne "\n\n\tWireless network card not up\n\n"                
                break
            fi
        fi
        clear
        header="\n%"$((bar_len + 9))"s |%5s |%8s |%10s | %-10s\n"
        printf "$header" "Signal" "dBm" "Quality" "Frequency" "SSID"
        parse_scan $scan_data
    else
        rssi=$(cat /proc/net/wireless | grep "$net:" | awk '{print $4}' | sed 's/\.//')
        get_output "$rssi"
        check_interface
    fi
done

exit
