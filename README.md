# Smappee Domoticz Bash Script
Bash script to get values from Smappee hub (locally) and upload them to Domoticz.

It uses Smappee local API and upload the extracted values to a Domoticz dummy sensor using the API.

## Author
I saw this great and original idea in [Domoticz Forums](https://www.domoticz.com/forum/viewtopic.php?f=31&t=7312&hilit=smappee&start=20) so all the credit goes to user **niceandeasy**.

I just improved the bash script code and documented this repo to help other users to set it up.

Any other suggestion will be welcome and pull-request are welcome too.

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
1. Clone this repo
  ```bash
  git clone https://github.com/apazga/smappee-domoticz-bash.git
  ```

1. Create the directory where the script will be (or use the one you prefer)
  ```bash
  mkdir -p /home/pi/_scripts/crons
  ```

1. Copy smappee_bash_extractor.sh to the desired location
  ```bash
  cp smappee-domoticz-bash/smappee_bash_extractor.sh  /home/pi/_scripts/crons
  ```

1. Add a new "Smappee" hardware in your Domoticz server as "Dummy (Does nothing, use for virtual switches only)"

1. Add four new "Virtual Sensors" to this new hardware (from Hardware list, button "Create Virtual Sensors"):
  ```
  Name: Energy Consumption
  Type: Electric (Instant+counter)

  Name: Voltage
  Type: Voltage

  Name: Ampere
  Type: Ampere (1 phase)

  Name: Cos Phi
  Type: Custom sensor
```

1. Edit required variables in `smappee_bash_extractor.sh` script. You should configure all variables included in "User configurable values zone".
  **WARNING**: Check twice the idx for each variable in your Domoticz Device list to ensure all match, to avoid "pushing" data to a different sensor
  You should configure the following variables:
  * DOMOTICZ_URL: Specify your Domoticz URL, using http or https (depending on your Domoticz configuration)
  * SMAPPEE_IP: The IP of your Smappee hub
  * TMPDIR: Temporary directory for the script (see section "Suggestion: Use a RAM Disk")
  * DOMOTICZ_WATTS_IDX: idx for your Electric (Instant+Counter) virtual sensor
  * DOMOTICZ_VOLTS_IDX: idx for your Voltage virtual sensor
  * DOMOTICZ_AMPS_IDX: idx for your Ampere (1 phase) virtual sensor
  * DOMOTICZ_COSF_IDX: idx for your Custom sensor (cos phi) virtual sensor

1. Test it before setting it as a cron job
  ```bash
  cd /home/pi/_scripts/crons
  chmod u+x smappee_bash_extractor.sh
  ./smappee_bash_extractor.sh
  ```

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
