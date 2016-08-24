# Smappee (www.smappee.com) collector bash script
# by niceandeasy (https://www.domoticz.com/forum/viewtopic.php?f=31&t=7312&start=40)
# improved by apazga (https://github.com/apazga/smappee-domoticz-bash)
#
# This single script takes Smappee data from its local API and uploads it to a Domoticz dummy sensor
#
####### Start User configurable values zone #######
DOMOTICZ_URL="http://127.0.0.1:8080"
SMAPPEE_IP="192.168.1.111"
TMPDIR="/var/tmp"

# Virtual sensors index
# Electric (Instant+Counter)
DOMOTICZ_WATTS_IDX="11"

# Voltage
DOMOTICZ_VOLTS_IDX="12"

# Ampere (1 phase)
DOMOTICZ_AMPS_IDX="13"

# Custom sensor (cos phi)
DOMOTICZ_COSF_IDX="14"
####### End user configurable values zone #######


####### Magic (do not touch!) #######
SMAP=`curl http://${SMAPPEE_IP}/gateway/apipublic/reportInstantaneousValues`
ERR=`echo $SMAP|grep -c Couldn`
# 'Couldn' means that curl couldn't do what's needed, for example, when Smappee's network connection is temporarily out
# So if no error, we continue to try to get values from Smappee
# Else, we get the previous values stored in $TMPDIR
if [ $ERR -ne 1 ]
then
ERR=`echo $SMAP|grep -c error`
# 'error' means that Smappee answered with an error, most likely, not logged in
if [ $ERR -eq 1 ]
then
  curl -H "Content-Type: application/json" -X POST -d "admin" http://$SMAPPEE_IP/gateway/apipublic/logon
  SMAP=`curl http://${SMAPPEE_IP}/gateway/apipublic/reportInstantaneousValues`
fi

VOLTS=`echo $SMAP |sed -e 's|.*voltage=\(.*\)|\1|' -e 's|\(.\{1,5\}\).*|\1|'`
WATTS=`echo $SMAP |sed -e 's|.* activePower=\(.*\)|\1|' -e 's|\(.\{1,6\}\).*|\1|'`
AMPS=`echo $SMAP |sed -e 's|.*urrent=\(.*\)|\1|' -e 's|\(.\{1,4\}\).*|\1|'`
COSF=`echo $SMAP |sed -e 's|.* cosfi=\(.*\)|\1|' -e 's|\(.\{1,2\}\).*|\1|'`
else
VOLTS=`cat $TMPDIR/volts`
WATTS=`cat $TMPDIR/watts`
AMPS=`cat $TMPDIR/amps`
COSF=`cat $TMPDIR/cosf`
fi
# just in case there's still nothing there...
if [ -z $VOLTS ]; then VOLTS=230; fi
if [ -z $WATTS ]; then WATTS=460; fi
if [ -z $AMPS ]; then AMPS=2; fi
if [ -z $COSF ]; then COSF=1; fi
# Save this. If Smappee is not in mood at next run, we'll use these instead.
echo $VOLTS > $TMPDIR/volts
echo $WATTS > $TMPDIR/watts
echo $AMPS  > $TMPDIR/amps
echo $COSF  > $TMPDIR/cosf
# Put the voltage, amps and cos phi to Domoticz
curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_VOLTS_IDX}&nvalue=0&svalue=${VOLTS}"
curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_AMPS_IDX}&nvalue=0&svalue=${AMPS}"
curl -k "${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_COSF_IDX}&nvalue=0&svalue=${COSF}"
# CUM is the cumulative watthour value
# Domoticz wants watthours, so that's why watthour
# To make sure we have a CUM value:
[ -f $TMPDIR/wh ] && echo wh present || echo 0.0001 > $TMPDIR/wh
CUM=`cat $TMPDIR/wh`
# In case there's still no good CUM yet..
if [ -z $CUM ]; then CUM=1; fi
# By resetting the WH cumulative like this, we might see strange jumps in the kWh usage graphs.
# But if WH fails ($TMPDIR/wh empty), Domoticz also stops showing and registering WATTs and the log fails.
#
#Calc new WattHour value
WH=`echo $WATTS\*0.0166667+$CUM|bc`
echo $WH > /$TMPDIR/wh
# the 0.0166667 number is 1/60, meaning, we take 60 measurements per hour, adding to the cumulative.
# Now put the watts and the watthours to Domoticz
CURLURL="${DOMOTICZ_URL}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_WATTS_IDX}&nvalue=0&svalue=${WATTS};${WH}"
curl -k $CURLURL
