#!/bin/bash
host="192.168.128.117:8050"
metrics="getOutputData"
info="getDeviceInfo"
ts=$(date +%Y-%m-%dT%H:%M:%S+01:00)

data=$(curl -s http://$host/$metrics | jq -r '.data | join (" ")')

if test -n "$data"; then
 read -r -a params <<< "${data}"
 p1="${params[0]}"   # power generating on channel 1
 e1="${params[1]}"   # energy generated since startup on channel 1
 te1="${params[2]}"  # lifetime energy generated on channel 1
 p2="${params[3]}"
 e2="${params[4]}"
 te2="${params[5]}"
else
    echo "$ts got no data!"
    exit
fi

infodata=$(curl -s http://$host/$info | jq -r '.data | join (" ")')

if test -n "$infodata"; then
 read -r -a params <<< "${infodata}"
 deviceid="${params[0]}"
 device="${params[1]}"
 version="${params[2]}"
 ssid="${params[3]}" 
 ip="${params[4]}"
 minpower="${params[5]}"
 maxpower="${params[6]}"
else
    echo "$ts got no info!"
    exit
fi

if test -n "$p1" -a -n "$ip"; then
    echo "ts=$ts p1=$p1 p2=$p2 ip=$ip version=$version deviceid=$deviceid ssid=$ssid minpower=$minpower maxpower=$maxpower"
else
    echo "$ts got invalid data!"
fi
