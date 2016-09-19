# Smappee (www.smappee.com) plugs control bash script
# by apazga (https://github.com/apazga/smappee-domoticz-bash)
#
# Use it without commands to see help & examples

####### Start User configurable values zone #######
SMAPPEE_IP="192.168.1.111"
####### End user configurable values zone #######


####### Magic (do not touch!) #######
if [ "$1" == "list" ]
then
  echo -e "\n\e[33mListing available plugs\e[0m"
  echo -e "\e[36mLogin...\e[0m"
  curl -H "Content-Type: application/json" -X POST -d "admin" http://$SMAPPEE_IP/gateway/apipublic/logon
  echo -e "\n\n\e[92mAvailable plugs:\e[0m"
  curl -H "Content-Type: application/json" -X POST -d "load" http://$SMAPPEE_IP/gateway/apipublic/commandControlPublic
  echo -e "\n"
  exit 0
elif [ $# -ne 2 ]
then
  echo -e "\e[33mSyntax: $0  command  plug_key\e[0m"
  echo -e "\e[36mExample 1: $0 list\e[0m --> List available plugs"
  echo -e "\e[36mExample 2: $0 1 3\e[0m  --> Set plug 3 to on"
  echo -e "\e[36mExample 3: $0 2 3\e[0m  --> Set plug 3 to off"
  exit 1
fi

# Power on/off plug
curl -H "Content-Type: application/json" -X POST -d "admin" http://$SMAPPEE_IP/gateway/apipublic/logon
curl -H "Content-Type: application/json" -X POST -d "control,controlId=$1|$2" http://$SMAPPEE_IP/gateway/apipublic/commandControlPublic
