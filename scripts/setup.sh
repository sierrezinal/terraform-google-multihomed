!/bin/bash
set -euo pipefail

# Assumptions:
# (1) subnets are in the /20 CIDR range
# (2) there are 2 network interfaces on this guest VM.

defaultInterface=$(ip route | awk 'FNR==1 {print $5}')
echo "default interface = $defaultInterface"

[[ -z "$defaultInterface" ]] && { echo "Unexpected missing default configured interface" ; exit 1; }

foundit='false'
foundline=''
addr=$(/bin/ip -br address) 

shopt -s lastpipe

echo "$addr" | { while read -r line ; do 
   k=$(echo -e "$line" | awk -v IFS=$'\t' '{print $1}')

   if [[ "$k" == "$defaultInterface" ]]; then
           continue
   fi

   if [[ "$k" == "lo" ]]; then
           continue
   fi

   foundit='true'
   foundline="$line"
   break
done }

shopt -u lastpipe

if [[ "$foundit" == "true" ]]; then
   k=$(echo -e "$foundline" | awk -v IFS=$'\t' '{print $1}')
   ipa=$(ip -4 a show dev "$k" | awk 'FNR==2 {n=split($2,ip,"/"); print ip[1]}')

   gateway=$(echo "$ipa" | awk -F'.' '{n=split($0,ip,"."); print ip[1]"."ip[2]"."ip[3]".1"}')
   cidr=$(echo "$ipa" | awk -F'.' '{n=split($0,ip,"."); print ip[1]"."ip[2]"."ip[3]".0/20"}')
   grep -E '^1\b' /etc/iproute2/rt_tables || echo -e "1\tspecial"  | sudo tee --append /etc/iproute2/rt_tables

   sudo ip route add default via "$gateway" dev "$k" table special
   sudo ip route add "$cidr" dev "$k" src "$ipa" table special
   sudo ip rule add to "$cidr" table special
   sudo ip rule add from "$cidr" table special
   sudo ip rule add oif "$k" table special

   sudo ip route flush cache
fi
