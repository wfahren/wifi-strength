# wifi-strength.sh and wifi-strength.bash
<h4>Small shell script to scan for 802.11 AP's or monitor a connected link with text based bar graph.</h2>

Script Dedency: B{ASH} like shell and iw. No other package requirements.

Must be ran as user root or sudo. The iw scan command requires root access.

 The SSID and signal strength are from iw output, others are
 calulated like Quality and GOOD to BAD signal.

---
 
Usage: wifi-strength.sh [options] \<interface\>

\<interface\>  The interface to monitor. 

[options]

	-m	Monitor link signal strength.
	-n	Display x number of lines
  	-f	Force monitoring even if interface does not exist.
  	-l	Length of strength bar, range 1-100, Default 50

Example:
  Scan AP's on interface wlan1;

	wifi-strength.sh wlan1

 ![image](https://github.com/user-attachments/assets/0a1844ee-f756-4da9-9ea3-d4d5ea64c064)


  Scan AP's on interface wlan1 and set strength bar length to 80;

	wifi-strength.sh -l 80 wlan1

  Monitor station connection on interface wlan1 (coneection to another AP)

	wifi-strength.sh -m wlan1

![image](https://github.com/user-attachments/assets/7408c43a-432c-4dd1-9ad4-e7fc062ca02f)
 

