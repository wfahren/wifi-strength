# wifi-strength.sh
<h4>Small shell script to scan for 802.11 AP's or monitor a connected link with text based bar graph. Designed to work with openWrt</h2>

Script Dedency: B{ASH} like shell and iw. No other package requirements. Must be ran as user root or sudo. The iw scan command requires root access.

---
 
Usage: wifi-strength.sh [options] \<interface\>

\<interface\>  The interface device to monitor. 

[options]

  -m	Monitor link signal strength.
  -n	Display x number of lines
  -i	Set scan interval, default 5 seconds
  -l	Length of strength bar, range 1-100, Default 50
  -p	Passive scan, default active scan

Example:
  Scan AP's on interface wlan1;

	wifi-strength.sh wlan1

 ![image](https://github.com/user-attachments/assets/dc398372-ce7b-4853-a795-32efba82aa69)


  Scan AP's on interface wlan1 and set strength bar length to 80;

	wifi-strength.sh -l 80 wlan1

  Monitor station connection on interface wlan1 (connected to another AP)

	wifi-strength.sh -m wlan1

![image](https://github.com/user-attachments/assets/30ed3dd9-882b-42c4-a982-7697a92a84f9)

 

