# Smappee (www.smappee.com) collector bash script
# Original idea by niceandeasy (https://www.domoticz.com/forum/viewtopic.php?f=31&t=7312&start=40)
# Improved & continued by apazga (https://github.com/apazga/smappee-domoticz-bash)
#
# This single script takes Smappee data from its local API and uploads it to a Domoticz dummy sensor
#
####### Start User configurable values zone #######
DOMOTICZ_URL="http://127.0.0.1:8080"
SMAPPEE_IP="192.168.1.111"
TMPDIR="/var/tmp"

# Single phase (1) or Three-Phase (0) electric power
# 
SINGLE_PHASE=1

# Virtual sensors index and enable flags (to use them or not)
# Enable values you want to read & push to Domoticz (1 to enable or 0 to disable)

# Watts - Electric (Instant+Counter). Enabled by default
## Single Phase
DOMOTICZ_WATTS_IDX="11"
## Three Phase
DOMOTICZ_WATTS_P1_IDX="21"
DOMOTICZ_WATTS_P2_IDX="22"
DOMOTICZ_WATTS_P3_IDX="23"

# Voltage (Single or Three phase). Enabled by default
DOMOTICZ_VOLTS_ENABLE=1
DOMOTICZ_VOLTS_IDX="12"

# Ampere (Single or Three phase). Enabled by default
DOMOTICZ_AMPS_ENABLE=1
DOMOTICZ_AMPS_IDX="13"

# Cos phi - Custom sensor (cos phi). Disabled by default
DOMOTICZ_COSF_ENABLE=0
## Single phase
DOMOTICZ_COSF_IDX="14"
## Three phase
DOMOTICZ_COSF_P1_IDX="24"
DOMOTICZ_COSF_P2_IDX="25"
DOMOTICZ_COSF_P3_IDX="26"

# Reactive power - Custom sensor (reactive, unit var). Disabled by default
DOMOTICZ_REACT_ENABLE=0
## Single phase
DOMOTICZ_REACT_IDX="15"
## Three phase
DOMOTICZ_REACT_P1_IDX="27"
DOMOTICZ_REACT_P2_IDX="28"
DOMOTICZ_REACT_P3_IDX="29"

# Apparent power - Custom sensor (apparent, unit VA). Disabled by default
DOMOTICZ_APPARENT_ENABLE=0
## Single phase
DOMOTICZ_APPARENT_IDX="16"
## Three phase
DOMOTICZ_APPARENT_P1_IDX="30"
DOMOTICZ_APPARENT_P2_IDX="31"
DOMOTICZ_APPARENT_P3_IDX="32"

## Development flags
# Push values to domoticz (1) or not (0). If not, they are displayed in stdout
DOMOTICZ_PUSH=0

####### End user configurable values zone #######


####### Magic (do not touch!) #######

# Required tools check
command -v bc > /dev/null 2>&1 || { echo >&2 "You need to install 'bc' package first"; exit 1; }
command -v curl > /dev/null 2>&1 || { echo >&2 "You need to install 'curl' package first"; exit 1; }

#seA Required temp dir check
if [ ! -d "$TMPDIR" ]; then
    echo "Create $TMPDIR first and (suggestion) mount is as a RAM disk.
    Check README.md for more information"
    exit 1
fi

# Get values from Smappee
SMAP=$(curl http://${SMAPPEE_IP}/gateway/apipublic/reportInstantaneousValues)
ERR=$(echo "$SMAP" | grep -c Couldn)
# 'Couldn' means that curl couldn't do what's needed, for example, when Smappee's network connection is temporarily out
# So if no error, we continue to try to get values from Smappee
# Else, we get the previous values stored in $TMPDIR
if [ "$ERR" -ne 1 ]
then
  # 'error' means that Smappee answered with an error, most likely, not logged in
  ERR=$(echo "$SMAP" | grep -c error)
  if [ "$ERR" -eq 1 ]
  then
    curl -H "Content-Type: application/json" -X POST -d "admin" http://$SMAPPEE_IP/gateway/apipublic/logon
    SMAP=$(curl http://${SMAPPEE_IP}/gateway/apipublic/reportInstantaneousValues)
  fi

  #
  # Get values from Smappee answer
  #
  VALUES=$(echo "$SMAP" | tr '<BR>' "\n" | awk '/current/')

  # Voltage
  VOLTS=$(echo "$SMAP" | sed -e 's|.*voltage=\(.*\)|\1|' -e 's|\(.\{1,5\}\).*|\1|' | head -1)

  # Single phase values
  if [ $SINGLE_PHASE -eq 1 ]; then
      # Ampere
      WATTS=$(echo "$VALUES" | awk -F'=' '{print $2}' | cut -c1-4)
      
      # Watts
      WATTS=$(echo "$VALUES" | awk -F'=' '{print $3}' | cut -c1-6)

      # React
      REACT=$(echo "$VALUES" | awk -F'=' '{print $4}' | cut -c1-5)

      # React
      APPARENT=$(echo "$VALUES" | awk -F'=' '{print $5}' | cut -c1-5)

      # Cosf
      COSF=$(echo "$VALUES" | awk -F'=' '{print $6}' | cut -c1-c2)

  # Three phase values
  else
      # Ampere
      AMPS_3P=""
      for i in $(echo "$VALUES" | awk -F'=' '{print $2}' | cut -c1-4)
      do
          AMPS_3P="$AMPS_3P;$i"
      done
      AMPS=${AMPS_3P#";"}

      # Watts
      WATTS_3P=$(echo "$VALUES" | awk -F'=' '{print $3}' | cut -c1-6)
      WATTS_P1=$(echo "$WATTS_3P" | awk 'NR==1')
      WATTS_P2=$(echo "$WATTS_3P" | awk 'NR==2')
      WATTS_P3=$(echo "$WATTS_3P" | awk 'NR==3')

      # React
      REACT_3P=$(echo "$VALUES" | awk -F'=' '{print $4}' | cut -c1-5)
      REACT_P1=$(echo "$REACT_3P" | awk 'NR==1')
      REACT_P2=$(echo "$REACT_3P" | awk 'NR==2')
      REACT_P3=$(echo "$REACT_3P" | awk 'NR==3')

      # Apparent
      APPARENT_3P=$(echo "$VALUES" | awk -F'=' '{print $5}' | cut -c1-6)
      APPARENT_P1=$(echo "$APPARENT_3P" | awk 'NR==1')
      APPARENT_P2=$(echo "$APPARENT_3P" | awk 'NR==2')
      APPARENT_P3=$(echo "$APPARENT_3P" | awk 'NR==3')

      # Cosfi
      COSF_3P=$(echo "$VALUES" | awk -F'=' '{print $6}' | cut -c1-2)
      COSF_P1=$(echo "$COSF_3P" | awk 'NR==1')
      COSF_P2=$(echo "$COSF_3P" | awk 'NR==2')
      COSF_P3=$(echo "$COSF_3P" | awk 'NR==3')


  fi

else
        VOLTS=$(cat $TMPDIR/volts)
        AMPS=$(cat $TMPDIR/amps)
    if [ $SINGLE_PHASE -eq 1 ]; then
        WATTS=$(cat $TMPDIR/watts)
        COSF=$(cat $TMPDIR/cosf)
        REACT=$(cat $TMPDIR/react)
        APPARENT=$(cat $TMPDIR/apparent)
    else
        WATTS_P1=$(cat $TMPDIR/watts_p1)
        WATTS_P2=$(cat $TMPDIR/watts_p2)
        WATTS_P3=$(cat $TMPDIR/watts_p3)
        
        REACT_P1=$(cat $TMPDIR/react_p1)
        REACT_P2=$(cat $TMPDIR/react_p2)
        REACT_P3=$(cat $TMPDIR/react_p3)

        APPARENT_P1=$(cat $TMPDIR/apparent_p1)
        APPARENT_P2=$(cat $TMPDIR/apparent_p2)
        APPARENT_P3=$(cat $TMPDIR/apparent_p3)

        COSF_P1=$(cat $TMPDIR/cosf_p1)
        COSF_P2=$(cat $TMPDIR/cosf_p2)
        COSF_P3=$(cat $TMPDIR/cosf_p3)
    fi
fi

# Just in case there's still nothing there...
if [ -z "$VOLTS" ]; then VOLTS=230; fi

if [ $SINGLE_PHASE -eq 1 ]; then
    if [ -z "$AMPS" ]; then AMPS=2; fi
    if [ -z "$WATTS" ]; then WATTS=100; fi
    if [ -z "$REACT" ]; then REACT=110; fi
    if [ -z "$APPARENT" ]; then APPARENT=120; fi
    if [ -z "$COSF" ]; then COSF=1; fi
    
    # echo to save values. If Smappee is not in mood at next run, we'll use these instead.
    echo $WATTS > $TMPDIR/watts 
    echo $REACT > $TMPDIR/react
    echo $APPARENT > $TMPDIR/apparent
    echo $COSF  > $TMPDIR/cosf
else
    if [ -z "$AMPS" ]; then AMPS="2;2;2"; fi
    if [ -z "$WATTS_P1" ]; then WATTS_P1=100; fi
    if [ -z "$WATTS_P2" ]; then WATTS_P2=100; fi
    if [ -z "$WATTS_P3" ]; then WATTS_P3=100; fi
    
    echo "$WATTS_P1" > $TMPDIR/watts_p1
    echo "$WATTS_P2" > $TMPDIR/watts_p2
    echo "$WATTS_P3" > $TMPDIR/watts_p3
    
    if [ -z "$REACT_P1" ]; then REACT_P1=110; fi
    if [ -z "$REACT_P2" ]; then REACT_P2=110; fi
    if [ -z "$REACT_P3" ]; then REACT_P3=110; fi
    echo "$REACT_P1" > $TMPDIR/react_p1
    echo "$REACT_P2" > $TMPDIR/react_p2
    echo "$REACT_P3" > $TMPDIR/react_p3

    if [ -z "$APPARENT_P1" ]; then APPARENT_P1=120; fi
    if [ -z "$APPARENT_P2" ]; then APPARENT_P2=120; fi
    if [ -z "$APPARENT_P3" ]; then APPARENT_P3=120; fi
    echo "$APPARENT_P1" > $TMPDIR/apparent_p1
    echo "$APPARENT_P2" > $TMPDIR/apparent_p2
    echo "$APPARENT_P3" > $TMPDIR/apparent_p3

    if [ -z "$COSF_P1" ]; then COSF_P1=1; fi
    if [ -z "$COSF_P2" ]; then COSF_P2=1; fi
    if [ -z "$COSF_P3" ]; then COSF_P3=1; fi
    echo "$COSF_P1" > $TMPDIR/cosf_p1
    echo "$COSF_P2" > $TMPDIR/cosf_p2
    echo "$COSF_P3" > $TMPDIR/cosf_p3
fi

echo $VOLTS > $TMPDIR/volts
echo $AMPS  > $TMPDIR/amps

# CUM is the cumulative watt/hour value
# Domoticz wants watt/hour, so that's why watt/hour
# To make sure we have a CUM value:
if [ $SINGLE_PHASE -eq 1 ]; then
    [ -f $TMPDIR/wh ] || echo 0.0001 > $TMPDIR/wh
    CUM=$(cat $TMPDIR/wh)
    
    # In case there's still no good CUM yet..
    if [ -z "$CUM" ]; then CUM=1; fi
    
    # By resetting the WH cumulative like this, we might see strange jumps in the kWh usage graphs.
    # But if WH fails ($TMPDIR/wh empty), Domoticz also stops showing and registering WATTs and the log fails.
    #
    # Calc new WattHour value
    WH=$(echo $WATTS\*0.0166667+$CUM|bc)
    echo "$WH" > /$TMPDIR/wh
    # 0.0166667 number is 1/60, meaning, we take 60 measurements per hour, adding to the cumulative.
else
    [ -f $TMPDIR/wh_p1 ] || echo 0.0001 > $TMPDIR/wh_p1
    [ -f $TMPDIR/wh_p2 ] || echo 0.0001 > $TMPDIR/wh_p2
    [ -f $TMPDIR/wh_p3 ] || echo 0.0001 > $TMPDIR/wh_p3

    CUM_P1=$(cat $TMPDIR/wh_p1)
    CUM_P2=$(cat $TMPDIR/wh_p2)
    CUM_P2=$(cat $TMPDIR/wh_p3)
    
    if [ -z "$CUM_P1" ]; then CUM_P1=1; fi
    if [ -z "$CUM_P2" ]; then CUM_P2=1; fi
    if [ -z "$CUM_P3" ]; then CUM_P3=1; fi

    WH_P1=$(echo "$WATTS_P1"\*0.0166667+$CUM_P1|bc)
    WH_P2=$(echo "$WATTS_P2"\*0.0166667+$CUM_P2|bc)
    WH_P3=$(echo "$WATTS_P3"\*0.0166667+$CUM_P3|bc)

    echo "$WH_P1" > $TMPDIR/wh_p1
    echo "$WH_P2" > $TMPDIR/wh_p2
    echo "$WH_P3" > $TMPDIR/wh_p3
fi


# Push values to Domoticz
if [ $DOMOTICZ_PUSH -eq 1 ]
then
  # Push enabled values to Domoticz
  if [ "$DOMOTICZ_VOLTS_ENABLE" -eq 1 ]; then
    curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_VOLTS_IDX}&nvalue=0&svalue=${VOLTS}"
  fi
  if [ "$DOMOTICZ_AMPS_ENABLE" -eq 1 ]; then
    curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_AMPS_IDX}&nvalue=0&svalue=${AMPS}"
  fi
  if [ "$DOMOTICZ_COSF_ENABLE" -eq 1 ]; then
      if [ $SINGLE_PHASE -eq 1 ]; then
          curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_COSF_IDX}&nvalue=0&svalue=${COSF}"
      else
          CURLURL_P1="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_COSF_P1_IDX}&nvalue=0&svalue=${COSF_P1}"
          CURLURL_P2="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_COSF_P2_IDX}&nvalue=0&svalue=${COSF_P2}"
          CURLURL_P3="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_COSF_P3_IDX}&nvalue=0&svalue=${COSF_P3}"
          curl -k "$CURLURL_P1"
          curl -k "$CURLURL_P2"
          curl -k "$CURLURL_P3"
      fi
  fi
  if [ "$DOMOTICZ_REACT_ENABLE" -eq 1 ]; then
      if [ $SINGLE_PHASE -eq 1 ]; then
          curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_REACT_IDX}&nvalue=0&svalue=${REACT}"
      else
          CURLURL_P1="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_REACT_P1_IDX}&nvalue=0&svalue=${REACT_P1}"
          CURLURL_P2="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_REACT_P2_IDX}&nvalue=0&svalue=${REACT_P2}"
          CURLURL_P3="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_REACT_P3_IDX}&nvalue=0&svalue=${REACT_P3}"
          curl -k "$CURLURL_P1"
          curl -k "$CURLURL_P2"
          curl -k "$CURLURL_P3"
      fi
  fi
  if [ "$DOMOTICZ_APPARENT_ENABLE" -eq 1 ]; then
      if [ $SINGLE_PHASE -eq 1 ]; then
          curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_APPARENT_IDX}&nvalue=0&svalue=${APPARENT}"
      else
          CURLURL_P1="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_APPARENT_P1_IDX}&nvalue=0&svalue=${APPARENT_P1}"
          CURLURL_P2="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_APPARENT_P2_IDX}&nvalue=0&svalue=${APPARENT_P2}"
          CURLURL_P3="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_APPARENT_P3_IDX}&nvalue=0&svalue=${APPARENT_P3}"
          curl -k "$CURLURL_P1"
          curl -k "$CURLURL_P2"
          curl -k "$CURLURL_P3"
      fi
  fi

  # Push watts and watt/hour to Domoticz
  if [ $SINGLE_PHASE -eq 1 ]; then
    CURLURL="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_WATTS_IDX}&nvalue=0&svalue=${WATTS};${WH}"
    curl -k "$CURLURL"
  else
    CURLURL_P1="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_WATTS_P1_IDX}&nvalue=0&svalue=${WATTS_P1};${WH_P1}"
    CURLURL_P2="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_WATTS_P2_IDX}&nvalue=0&svalue=${WATTS_P2};${WH_P2}"
    CURLURL_P3="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_WATTS_P3_IDX}&nvalue=0&svalue=${WATTS_P3};${WH_P3}"
    curl -k "$CURLURL_P1"
    curl -k "$CURLURL_P2"
    curl -k "$CURLURL_P3"
  fi

else
  if [ $SINGLE_PHASE -ne 1 ]; then
    WATTS="${WATTS_P1};${WATTS_P2};${WATTS_P3}"
    COSF="${COSF_P1};${COSF_P2};${COSF_P3}"
    REACT="${REACT_P1};${REACT_P2};${REACT_P3}"
    APPARENT="${APPARENT_P1};${APPARENT_P2};${APPARENT_P3}"
    WH="${WH_P1};${WH_P2};${WH_P3}" 
  fi
  echo "Domoticz push disabled. Values:
    - Volts: ${VOLTS}
    - Amps: ${AMPS}
    - CosPhi: ${COSF}
    - Active power (watts): ${WATTS}
    - Reactive power (var): ${REACT}
    - Apparent power (VA): ${APPARENT}
    - Watts/hour: ${WH}"
fi
