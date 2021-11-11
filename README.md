# wifi-strength.sh and wifi-strength.bash
<h4>Small shell script to scan for 802.11 masters (APs) or monitor a link with text based bar graph.</h2>

Script Dedency: B{ASH} like shell and iw. No other package requirements.

There are two scripts .sh and .bash. The .sh was designed to work work openWRT firmware on a wireless router
and the .bash for Linux desktop, both need to be ran as user root or sudo. The iw scan command require root access.


 The SSID and signal strength are from iw output, others are
 calulated like Quality and GOOD to BAD signal.

 
Usage: wifi-strength.sh [options] \<interface\>

\<interface\>  The interface to monitor. 

[options]

	-m	Monitor link signal strenght.
  	-s	Sort scan results.
	-n	Display x number of lines
  	-f	Force monitoring even if interface does not exist.
  	-l	Length of strength bar, range 1-100, Default 50

Example:
  Scan for "masters" on interface wlan1;

	wifi-strength.sh wlan1

  Scan for "masters" on wlan1 set strength bar length to 80 
  and sort SSID's strongest to weakest signal;

	wifi-strength.sh -l 80 -s wlan1

  Monitor with bar graph on interface wlan1

	wifi-strength.sh -l 75 -m wlan1
