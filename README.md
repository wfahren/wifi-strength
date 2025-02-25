# wifi-strength.sh
<h4>Small shell script to scan for 802.11 AP's or monitor a connected link with text based bar graph. Designed to work with openWrt</h2>

Script Dedency: B(ASH) like shell and iw. No other package requirements. Must be ran as user root or sudo. The iw scan command requires root access.

---
### Help 
 `./wifi-strength.sh -h`

### Usage
	
	Usage: wifi-strength.sh [options] <interface>
	
	<interface>  The interface to monitor. 
	
	[options]
	  -m	Monitor link signal strength.
	  -n	Display x number of lines
	  -i	Set scan interval, default 5 seconds
	  -l	Length of strength bar, range 1-100, Default 50
	  -a	Active scan, default passive scan. (Active scan sends Beacon's) 
	Example:
	  Scan for "masters" on interface wlan1;
	
		wifi-strength.sh wlp4s0
	
	  Scan AP's on wlan1 set strength bar length to 10;
	
		wifi-strength.sh -l 10 wlp4s0
	
	  Monitor client connection on interface wlan1
	
		wifi-strength.sh -m wlp4s0
	
	
	Interfaces found:
	wlp4s0



Example:
  Scan AP's on interface wlan1;

	wifi-strength.sh wlp4s0

 ![image](https://github.com/user-attachments/assets/34148ee3-3a3b-4e61-aa59-83897fb0da1f)

  Scan AP's on interface wlan1 and set strength bar length to 80;

	wifi-strength.sh -l 80 wlp4s0

  Monitor station connection on interface wlan1 (connected to another AP)

	wifi-strength.sh -m wlp4s0

![image](https://github.com/user-attachments/assets/695896d8-3edc-4e15-89dd-fdbdf44191e0)


 

