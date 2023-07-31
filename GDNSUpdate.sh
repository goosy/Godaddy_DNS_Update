#!/bin/bash
# This script checks and automatically updates the records
# of your GoDaddy DNS server with your current WAN IP address.

# godaddy token
GD_Key="your_godaddy_key"
GD_Secret="your_godaddy_secret"
# list of record to update
# "domain host" in each line
records=(
    "domain1.ddns @"
    "domain2.ddns blog"
)

headers="Authorization: sso-key $GD_Key:$GD_Secret"
# echo $headers
for record in "${records[@]}"; do
    pair=($record)
    domain="${pair[0]}"
    hostname="${pair[1]}"

    dns_a_data=$(curl -s -X GET -H "$headers" "https://api.godaddy.com/v1/domains/$domain/records/A/$hostname")
    #echo $dns_a_data
    GDIP4=$(echo $dns_a_data | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
    #echo "GDIP4:" $GDIP4
    myIPV4=`curl -s "https://api.ipify.org"`
    #echo "myIPV4:" $myIPV4

    if [ "$GDIP4" != "$myIPV4" -a "$myIPV4" != "" ]; then
        # echo "Ips are not equal"
        req4='[{"data":"'$myIPV4'","ttl":600}]'
        # echo " req4:" $req4
        ret4=$(curl -i -s -X PUT \
            -H "$headers" \
            -H "Content-Type: application/json" \
            -d $req4 \
            "https://api.godaddy.com/v1/domains/$domain/records/A/$hostname")
        # echo "ret4:" $ret4
    fi

    dns_aaaa_data=$(curl -s -X GET -H "$headers" "https://api.godaddy.com/v1/domains/$domain/records/AAAA/$hostname")
    #echo $dns_aaaa_data
    GDIP6=$(echo $dns_aaaa_data | cut -d ',' -f 1 | tr -d '"' | cut -d ":" -f 2-9)
    #echo "GDIP6:" $GDIP6
    myIPV6=`curl -s "https://api6.ipify.org"`
    #echo "myIPV6:" $myIPV6

    if [ "$GDIP6" != "$myIPV6" -a "$myIPV6" != "" ]; then
        # echo "Ips are not equal"
        req6='[{"data":"'$myIPV6'","ttl":600}]'
        # echo " req6:" $req6
        ret6=$(curl -s -X PUT \
            -H "$headers" \
            -H "Content-Type: application/json" \
            -d $req6 \
            "https://api.godaddy.com/v1/domains/$domain/records/AAAA/$hostname")
        # echo "ret6:" $ret6
    fi
done
