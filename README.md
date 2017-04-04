**Table of Contents**

- [Smappee Domoticz Bash Scripts](#smappee-domoticz-bash-scripts)
  - [Author](#author)
  - [Requirements](#requirements)
  - [How to use it](#how-to-use-it)
  - [Cron example to run this script every minute](#cron-example-to-run-this-script-every-minute)
  - [Suggestion: Use a RAM Disk](#suggestion-use-a-ram-disk)
  - [Controlling Smappee plugs from Domoticz](#controlling-smappee-plugs-from-domoticz)

# Smappee Domoticz Bash Scripts
Bash scripts to:
- Gather values from Smappee hub (locally) and upload them to Domoticz
- Control Smappee plugs

Scripts use Smappee local API to control plugs and to get the Smappee data. A dummy sensor and Domoticz API is used to push the data.

## Author
I saw the initial great and original idea in [Domoticz Forums](https://www.domoticz.com/forum/viewtopic.php?f=31&t=7312&hilit=smappee&start=20) so all the credit goes to user **niceandeasy**.

I just improved the bash script code and documented this repo to help other users to set it up and added a secondary script to control Smappee plugs.

Any other suggestion will be welcome and pull-requests are welcome too.

## Requirements
3 basic commands are required in the script:
* **curl**: for HTTP requests
* **sed**: for sifting out what we need from Smappee's output
* **bc**: for calculating cumulative usage

To ensure you have them all, just do the following:
```bash
sudo apt-get update && sudo apt-get install curl sed bc
```

## How to use it
1) Clone this repo
  ```bash
  git clone https://github.com/apazga/smappee-domoticz-bash.git
  ```

2) Create the directory where the script will be (or use the one you prefer)
  ```bash
  mkdir -p /home/pi/_scripts/crons
  ```

3) Copy smappee_bash_extractor.sh to the desired location
  ```bash
  cp smappee-domoticz-bash/smappee_bash_extractor.sh  /home/pi/_scripts/crons
  ```

4) Add a new "Smappee" hardware in your Domoticz server as "Dummy (Does nothing, use for virtual switches only)"

5) Add new "Virtual Sensors" to this new hardware (from Hardware list, button "Create Virtual Sensors"):
  ```
  Name: Energy Consumption
  Type: Electric (Instant+counter)

  Name: Voltage
  Type: Voltage

  Name: Ampere
  Type: Ampere (1 phase or 3 phase, depending on your case)

  Name: Cos Phi
  Type: Custom sensor

  Name: Reactive power
  Type: Custom sensor
  
  Name: Apparent power
  Type: Custom sensor
```

6) Edit required variables in `smappee_bash_extractor.sh` script. You should configure all variables included in "User configurable values zone".
  **WARNING**: Check twice the idx for each variable in your Domoticz Device list to ensure all match, to avoid "pushing" data to a different sensor

  First enable the values you want to use in Domoticz. Every variable has its own "DOMOTICZ_XXXX_ENABLE". e.g.:
  ```bash
  DOMOTICZ_VOLTS_ENABLE=1
  DOMOTICZ_AMPS_ENABLE=1
  DOMOTICZ_COSF_ENABLE=0
  ...
  ```

  You should configure the following variables:
  * **DOMOTICZ_URL**: Specify your Domoticz URL, using http or https (depending on your Domoticz configuration)
  * **DOMOTICZ_USERPASS**: If you need authentication, uncomment and use the given format "-u myuser:mypass"
  * **SMAPPEE_IP**: The IP of your Smappee hub
  * **TMPDIR**: Temporary directory for the script (see section "Suggestion: Use a RAM Disk")
  * **DOMOTICZ_WATTS_IDX**: idx for your Electric (Instant+Counter) virtual sensor
  * **DOMOTICZ_VOLTS_IDX**: idx for your Voltage virtual sensor
  * **DOMOTICZ_AMPS_IDX**: idx for your Ampere (1 phase) virtual sensor
  * **DOMOTICZ_COSF_IDX**: idx for your Custom sensor (cos phi) virtual sensor
  * **DOMOTICZ_REACT_IDX**: idx for your Custom sensor (reactive power) virtual sensor
  * **DOMOTICZ_APPARENT_IDX**: idx for your Custom sensor (apparent power) virtual sensor

**NOTE**: Three phase variables are similar (you'll find them in the code), but you'll need one sensor for each value, e.g.: 
```bash
DOMOTICZ_WATTS_P1_IDX="21"
DOMOTICZ_WATTS_P2_IDX="22"
DOMOTICZ_WATTS_P3_IDX="23"
...
```

7) Test it before setting it as a cron job
  ```bash
  cd /home/pi/_scripts/crons
  chmod u+x smappee_bash_extractor.sh
  ./smappee_bash_extractor.sh
  ```
  You can also use "DOMOTICZ_PUSH=0" variable, to test the output without pushing any value to Domoticz.


## Cron example to run this script every minute
Add the following line to your user crontab (`crontab -e`)
```bash
*/1 * * * *    /home/pi/_scripts/crons/smappee_bash_extractor.sh
```

## Suggestion: Use a RAM Disk
Due to we are writing every minute, it's highly recommended to create a RAM disk.

To simplify the process, if you want to create 1 MByte RAM disk in your /var/tmp directory, just add the following line at the end of `/etc/fstab` and do `sudo mount -a` or `reboot`.

```bash
tmpfs /var/tmp tmpfs nodev,nosuid,size=1M 0 0
```

More info and RAM Disk tutorial here: http://www.domoticz.com/wiki/Setting_up_a_RAM_drive_on_Raspberry_Pi

## Controlling Smappee plugs from Domoticz

**First, in your Domoticz server terminal**

1. Copy smappee_plug_control.sh to the desired location
  ```bash
  cp smappee-domoticz-bash/smappee_plug_control.sh  /home/pi/_scripts/
  ```

1. Edit the script to set your Smappee IP.

1. Run the script with "list" parameter to list your available plugs using the local API.
```bash
chmod u+x smappee_plug_control.sh
./smappee_plug_control.sh list
```

You'll see an output like this one:
```bash
Listing available plugs
Login...
{"success":"Logon successful!","header":"Logon to the monitor portal successful..."}

Available plugs:
[{"value":"My plug 1 ","key":"1"},{"value":"My plug 2 ","key":"3"}]
```

**Then, in your Domoticz web:**

1. Add a new "Manual Switch" in your Domoticz server and use Switch Type "On/Off" and Type "X10" (type isn't important here).

1. Edit your new switch and set these scripts as "on/off" actions:
```bash
On action: script:///home/pi/_scripts/smappee_plug_control.sh 1 3
Off action: script:///home/pi/_scripts/smappee_plug_control.sh 0 3
```

These commands should power on/off the plug with key (id) 3, that will be "My plug 2" from the previous example.
