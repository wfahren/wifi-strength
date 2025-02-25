# wifi-strength.sh
<h4>Small shell script to scan for 802.11 AP's or monitor a connected link with text based bar graph. Designed to work with openWrt</h2>

Script Dependency: B(ASH) like shell and iw. No other package requirements. Must be run as user root or sudo. The iw scan command requires root access.

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
   	  -f	Filter results, use extended grep pattern. Example: -f 'Whispering|MESH'

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
  Scan AP's on interface wlp4s0;

	wifi-strength.sh wlp4s0

 ![image](https://github.com/user-attachments/assets/34148ee3-3a3b-4e61-aa59-83897fb0da1f)

  Scan AP's on interface wlp4s0 and set strength bar length to 10 and filter on Whisp and MESH;

	wifi-strength.sh -l 10 -f 'Whisp|MESH' wlp4s0
 ![image](https://github.com/user-attachments/assets/2aa4e207-defe-4e05-a50f-353110b095ba)


  Monitor station connection on interface wlp4s0 (connected to another AP)

	wifi-strength.sh -m wlp4s0

![image](https://github.com/user-attachments/assets/695896d8-3edc-4e15-89dd-fdbdf44191e0)

Filter output using regex, example of filtering on anything that contains Whisp or MESH
case sensitive.

   	wifi-strength.sh -f 'Whisp|MESH' wlp4s0
    
 ![image](https://github.com/user-attachments/assets/85c0b768-8e50-4afc-a760-4653eef32682)


