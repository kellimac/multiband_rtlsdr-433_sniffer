# multiband_sdr_sniffer
Use an RTL-SDR dongle to frequency hop as a service

Casually coded by Kelli 'Katt' McMillan -- kelli@cativerse.com

**Use case:** Using an SDR dongle to monitor both the 433 and 915 mHz 
and other bands for temperature probe, utility meter and other 
wireless ISM band IoT device data using rtl_433.

This document describes in loose detail how to accomplish the 
installation of the rtl_433 software to use with an RTL-SDR dongle
and install a service that monitors both the 433 and 915 mHz
bands by frequency hopping.  It also spins up a tcp server to allow
a client to connect and collect decoded data from wireless IoT devices
in range over a TCP connection as JSON data. 

I have several Acurite temperature probes and other devices that 
transmit data in the 433 and 915 mHz bands, mostly as OOK data. 
The data received by the SDR receiver and decoded by rtl_433 
and passed on to a client for processing (display, triggering alarms, etc) 
as json data over a tcp server.

- I found that due to voltage fluctuations, loose connections on USB port and
a myriad of other reasons the cantankerous Raspberry Pi 2 might have for
losing connection to the SDR dongle, this process, while it can be done in 
a single command line, requires a failure monitor and auto restart function 
in order to be reliable enough to use for things like monitoring for higher than
normal temperature and other abbormal conditions via data received from IoT devices
by an SDR radio. 

- The process was quite reliable until I decided to add a second frequency and hop between
the two every minute or so. This causes the rtl_433 process to fail, sometimes several times
per day. I observed that the CPU time used by the rtl_433 process drops to 0 when this failure occurs
and that the CPU % is normally between 40-55% on my Rasbperry Pi 2B.

- This project addresses those issues by installing the rtl_433 and tcp server commands as
a service and then monitoring the CPU load used by the rtl_433 process to trigger a service
kill and restart as needed.

#### Updates
- I will be adding details to this documentation and project, as this is just
part of a larger system. I currently use node-red to display the data from
this and other sources to monitor everything in my workshop from
battery temperatures to background ionizing radiation counts. 

If you appreciate my work and would like to support me: https://buymeacoffee.com/cativerse


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

#### Test the rtl_433 software

`rtl_433 -V`

rtl_433 should respond with a version number and other information confirming options installed

```
pi@sdrpi:~ $ rtl_433 -V
rtl_433 version 25.02-37-gc60f574f branch master at 202507111104 inputs file rtl_tcp RTL-SDR SoapySDR with TLS
pi@sdrpi:~ $
```

Example test commands:

Use default SDR decice, set gain to auto, bandwidth to 1.4 mHz and center frequency to 433.900 mHz. Output to console.

`rtl_433 -g auto -s 1400000 -f 433900000` 

Same as above but add autoleveling, and pipe to a tcp server on localhost port 8000

`rtl_433 -g auto -s 1400000 -f 433900000 -M level -Y auto -Y level=0 -Y autolevel -F json | nc -lk 127.0.0.1 8000`

Use device 0, set gain to 49, bandwidth to 2.4 mHz, and hop between 315.000 mHz, 433.920 mHz and 868.000 mHz every 33 seconds. Output to console.

```rtl_433 -d 0 -g 49 -s 2400000 -H 33 -f 315000000 -f 433920000 -f 868000000``` 

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


