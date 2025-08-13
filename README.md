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

Use default SDR device, set gain to auto, bandwidth to 1.4 mHz and center frequency to 433.900 mHz. Output to console.

`rtl_433 -g auto -s 1400000 -f 433900000` 

Same as above but add autoleveling, and pipe in JSON format to a tcp server on localhost port 8000

`rtl_433 -g auto -s 1400000 -f 433900000 -M level -Y auto -Y level=0 -Y autolevel -F json | nc -lk 127.0.0.1 8000`

Use device 0, set gain to 49, bandwidth to 2.4 mHz, and hop between 315.000 mHz, 433.920 mHz and 868.000 mHz every 33 seconds. Output to console.

```rtl_433 -d 0 -g 49 -s 2400000 -H 33 -f 315000000 -f 433920000 -f 868000000``` 

#### rtl_433 test example output

```
pi@sdrpi:~ $ rtl_433 -g 40 -s 1200000 -f 433920000 -f 915000000 -H 45 -M level -Y auto -Y level=0 -Y autolevel
rtl_433 version 25.02-37-gc60f574f branch master at 202507111104 inputs file rtl_tcp RTL-SDR SoapySDR with TLS
Found Rafael Micro R820T tuner
[SDR] Using device 0: Realtek, RTL2838UHIDIR, SN: 72346005, "Generic RTL2832U OEM"
[R82XX] PLL not locked!
Allocating 15 zero-copy buffers
[Auto Level] Estimated noise level is -17.0 dB, adjusting minimum detection level to -14.0 dB
[Auto Level] Estimated noise level is -18.6 dB, adjusting minimum detection level to -15.6 dB
[Auto Level] Estimated noise level is -20.1 dB, adjusting minimum detection level to -17.1 dB
[Auto Level] Estimated noise level is -21.3 dB, adjusting minimum detection level to -18.3 dB
[Auto Level] Estimated noise level is -22.4 dB, adjusting minimum detection level to -19.4 dB
[Auto Level] Estimated noise level is -24.2 dB, adjusting minimum detection level to -21.2 dB
[Auto Level] Estimated noise level is -25.6 dB, adjusting minimum detection level to -22.6 dB
[Auto Level] Estimated noise level is -26.6 dB, adjusting minimum detection level to -23.6 dB
[Auto Level] Estimated noise level is -27.8 dB, adjusting minimum detection level to -24.8 dB
[Auto Level] Estimated noise level is -28.9 dB, adjusting minimum detection level to -25.9 dB
[Auto Level] Estimated noise level is -29.9 dB, adjusting minimum detection level to -26.9 dB
^CSignal caught, exiting!
pi@sdrpi:~ $ 
```
Never use anything but CTRL-C to stop the rtl_433 process. Using CTRL-X or CTRL-Z may cause process to hang, which will
hold your SDR dongle hostage until you kill the process completely.

If this happens, you will get a device claim error.

```
pi@sdrpi:~ $ rtl_433 -g 40 -s 1200000 -f 433920000 -f 915000000 -H 45 -M level -Y auto -Y level=0 -Y autolevel
rtl_433 version 25.02-37-gc60f574f branch master at 202507111104 inputs file rtl_tcp RTL-SDR SoapySDR with TLS
usb_claim_interface error -6
[sdr_open_rtl] Failed to open rtlsdr device #0.
[sdr_open_rtl] Unable to open a device
pi@sdrpi:~ $ 
```

#### Getting your dongle back by killing hung rtl_433 process

1. Identify offending process by using ps aux command `ps aux | grep -e 'rtl'`
2. Kill the offending process(es) with kill command `sudo kill -9 *process pid*`


```
pi@sdrpi:~ $ ps aux | grep -e 'rtl'
root     20168  0.0  0.0   1972   416 ?        Ss   00:51   0:00 /usr/bin/sh -c exec rtl_433 -d:72346005 -g 42 -s 1800000 -f 433920000 -f 912400000 -H 58 -M level -Y auto -Y level=0 -Y autolevel -F json | nc -lk 10.1.5.85 8000
root     20169 44.7  1.1  70812 10608 ?        Sl   00:51   1:31 rtl_433 -d:72346005 -g 42 -s 1800000 -f 433920000 -f 912400000 -H 58 -M level -Y auto -Y level=0 -Y autolevel -F json
pi       20293  0.0  0.0   7448   488 pts/0    S+   00:54   0:00 grep --color=auto -e rtl
pi@sdrpi:~ $ sudo kill -9 20168
pi@sdrpi:~ $ sudo kill -9 20169
kill: (20169): No such process
pi@sdrpi:~ $ ps aux | grep -e 'rtl'
pi       20330  0.0  0.0   7448   512 pts/0    S+   00:55   0:00 grep --color=auto -e rtl
pi@sdrpi:~ $ 
```

#### Successful tests
If everything is working properly and with a decent antenna, the process should run and you should start to see telemetry from your devices (and probably your neighbors, too!)

```rtl_433 -g 40 -s 1200000 -f 433920000 -f 915000000 -H 45 -M level -Y auto -Y level=0 -Y autolevel```

Output:

```
pi@sdrpi:~ $ rtl_433 -g 40 -s 1200000 -f 433920000 -f 915000000 -H 45 -M level -Y auto -Y level=0 -Y autolevel
rtl_433 version 25.02-37-gc60f574f branch master at 202507111104 inputs file rtl_tcp RTL-SDR SoapySDR with TLS
Found Rafael Micro R820T tuner
[SDR] Using device 0: Realtek, RTL2838UHIDIR, SN: 72346005, "Generic RTL2832U OEM"
[R82XX] PLL not locked!
Allocating 15 zero-copy buffers
[Auto Level] Estimated noise level is -17.0 dB, adjusting minimum detection level to -14.0 dB
[Auto Level] Estimated noise level is -18.6 dB, adjusting minimum detection level to -15.6 dB
[Auto Level] Estimated noise level is -20.1 dB, adjusting minimum detection level to -17.1 dB
[Auto Level] Estimated noise level is -21.3 dB, adjusting minimum detection level to -18.3 dB
[Auto Level] Estimated noise level is -22.4 dB, adjusting minimum detection level to -19.4 dB
[Auto Level] Estimated noise level is -24.2 dB, adjusting minimum detection level to -21.2 dB
[Auto Level] Estimated noise level is -25.5 dB, adjusting minimum detection level to -22.5 dB
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
time      : 2025-08-13 01:15:08
model     : Acurite-606TX id        : 165
Channel   : 1            Battery   : 1             Button    : 0             Temperature: 27.7 C       Integrity : CHECKSUM
Modulation: ASK          Freq      : 433.9 MHz
RSSI      : -16.4 dB     SNR       : 14.9 dB       Noise     : -31.4 dB
[Auto Level] Estimated noise level is -26.7 dB, adjusting minimum detection level to -23.7 dB
[Auto Level] Estimated noise level is -27.8 dB, adjusting minimum detection level to -24.8 dB
[Auto Level] Estimated noise level is -28.9 dB, adjusting minimum detection level to -25.9 dB
[Auto Level] Estimated noise level is -29.9 dB, adjusting minimum detection level to -26.9 dB
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
time      : 2025-08-13 01:15:21
model     : LaCrosse-TX141THBv2                    Sensor ID : 6c
Channel   : 0            Battery   : 1             Temperature: 27.10 C      Humidity  : 67 %          Test?     : No            Integrity : CRC
Modulation: ASK          Freq      : 433.8 MHz
RSSI      : -8.6 dB      SNR       : 19.9 dB       Noise     : -28.5 dB
[Auto Level] Estimated noise level is -28.4 dB, adjusting minimum detection level to -25.4 dB
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
time      : 2025-08-13 01:15:21
model     : LaCrosse-TX141THBv2                    Sensor ID : 6c
Channel   : 0            Battery   : 1             Temperature: 27.10 C      Humidity  : 67 %          Test?     : No            Integrity : CRC
Modulation: ASK          Freq      : 433.8 MHz
RSSI      : -8.5 dB      SNR       : 20.8 dB       Noise     : -29.4 dB
[Auto Level] Estimated noise level is -29.5 dB, adjusting minimum detection level to -26.5 dB
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
time      : 2025-08-13 01:15:25
model     : Nexus-TH     House Code: 126
Channel   : 1            Battery   : 1             Temperature: 26.80 C      Humidity  : 39 %
Modulation: ASK          Freq      : 433.9 MHz
RSSI      : -18.1 dB     SNR       : 10.8 dB       Noise     : -28.9 dB
^CSignal caught, exiting!
pi@sdrpi:~ $ 
```



#### Running as a service with auto restart on failures

See [rtl433-sniff.service](https://github.com/kellimac/multiband_sdr_sniffer/blob/2ad2799d3eb7c22a944593eb7e1c75a818bbe041/rtl433-sniff.service)


#### Add the monitoring script to crontab
This is a bash script named [sdr_monitor.sh](https://github.com/kellimac/multiband_sdr_sniffer/blob/3b59022a01c10568a71f932a8a668da4752e07e2/sdr_monitor.sh) that checks the rtl_433 process CPU time and stops/restarts the rtl433-sniff service if needed.
This script can be located anywhere, but the cron job path must match the actual location.
In this example, the script is located in /home/pi/ 


##### May require sudo/superuser privileges
There is likely a way to allow a cron job not running as root to restart a service, but I just made my life easier by editing the root crontab

run ```sudo crontab -e``` and add the following line

`* * * * * bash /home/pi/sdr_monitor.sh`


Note that enabling this cron job means the system will check once per minute to see if rtl_433 is running and will attempt to restart the rtl433-sniff service
if it isn't. This may cause issues and confusion if you are doing something like testing rtl_433 commands or a new dongle, so you may need to temporarily 
disable the monitoring cron job by running `sudo crontab -e` again and remming out the monitoring command if you run into this situation.

`# * * * * * bash /home/pi/sdr_monitor.sh`


#### Common commands
```
sudo nano /etc/systemd/system/rtl433-sniff.service   # edit the service file to change frequencies, hop time, etc.
sudo systemctl daemon-reload               # required after editing a service file
sudo systemctl start rtl433-sniff.service  # start the sniffer service manually
sudo systemctl stop rtl433-sniff.service   # stop the sniffer service manually
```


#### Updates
- I will be adding details to this documentation and project, as this is just
part of a larger system. I currently use node-red to display the data from
this and other sources to monitor everything in my workshop from
battery temperatures to background ionizing radiation counts. 

If you appreciate my work and would like to support me: https://buymeacoffee.com/cativerse

