# multiband_sdr_sniffer
Use an RTL-SDR dongle to frequency hop as a service

Casually coded by Kelli 'Katt' McMillan -- kelli@cativerse.com

**Use case:** Using an SDR dongle to monitor both the 433 and 915 mHz 
and other bands for temperature probe, utility meter and other 
wireless ISM band IoT device data using rtl_433

I have several Acurite temperature probes and other devices that 
transmit data in the 433 and 915 mHz bands, mostly as OOK data. 
The data received by the SDR receiver and decoded by rtl_433 
and passed on to a client for processing (display, triggering alarms, etc) 
as json data over a tcp server.

This document describes in loose detail how to accomplish this.
I will be adding details to this documentation and project, as this is just
part of a larger system. I currently use node-red to display the data from
this and other sources to monitor everything in my workshop from
battery temperatures to background ionizing radiation counts. 


###### Thanks to [@merbanan](https://github.com/merbanan) and contributors for their hard work on the [rtl_433 project](https://github.com/merbanan/rtl_433.git) which is required for this project


#### Prerequisites
```
sudo apt update
sudo apt upgrade
sudo apt install build-essential cmake libssl-dev librtlsdr-dev 
sudo apt install rtl-sdr librtlsdr0-dev librtlsdr-dev
```



#### Building rtl_433 from source
```
git clone https://github.com/merbanan/rtl_433.git
cd rtl_433
mkdir build
cd build
cmake ..
make
sudo make install
```


#### Running as a service with auto restart on failures

See [rtl433-sniff.service](https://github.com/kellimac/multiband_sdr_sniffer/blob/2ad2799d3eb7c22a944593eb7e1c75a818bbe041/rtl433-sniff.service)

#### Add to crontab -e 
##### May require sudo/superuser privileges

`* * * * * bash /home/pi/sdr_monitor.sh`

#### Common commands
```
sudo nano /etc/systemd/system/rtl433-sniff.service   # edit the service file to change frequencies, hop time, etc.
sudo systemctl daemon-reload               # required after editing a service file
sudo systemctl start rtl433-sniff.service  # start the sniffer service manually
sudo systemctl stop rtl433-sniff.service   # stop the sniffer service manually
```


