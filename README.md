# wifi-strength.sh
Small shell script to scan for 802.11 masters (APs) or monitor a link with text based bar graph.



Usage: wifi-strength [options] <interface>

<interface>  The interface to monitor. 

[options]

	-m	Monitor link signal strenght.
  	-s	Sort scan results.
  	-f	Force monitoring even if interface does not exist.
  	-l	Length of strenght bar, range 1-100, Default 50
  	-bc	Bar strenght character use quotes, Default "#"
  	-bf	Bar fill character use quotes, Default Space " "

Example:
  Scan for "masters" on interface wlan1;

	wifi-strength wlan1

  Scan for "masters" on wlan1 set strength bar length to 80 
  and sort SSID's strongest to weakest signal;

	wifi-strength -l 80 -s wlan1

  Monitor with bar graph on interface wlan1

	wifi-strength -l 75 -m wlan1
