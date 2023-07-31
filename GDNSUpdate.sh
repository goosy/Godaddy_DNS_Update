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

auth_header="Authorization: sso-key $GD_Key:$GD_Secret"
# echo $auth_header

record_update() {
    myIP="$1"
    url="$2"
    dns_data=$(curl -s -X GET -H "$auth_header" "$url")
    # echo $dns_data
    GDIP=$(
        echo $dns_data | 
        grep -oE '\b(([0-9]{1,3}\.){3}[0-9]{1,3})|(([0-9a-f]{1,4}:){7}[0-9a-f]{1,4})\b'
    )
    # echo "$myIP" "$GDIP" "$url"
    if [ "$GDIP" != "$myIP" -a "$myIP" != "" ]; then
        # echo "Ips are not equal"
        request='[{"data":"'$myIP'","ttl":600}]'
        # echo "request:" $request
        result=$(curl -i -s -X PUT \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            -d $request \
            "$url")
        # echo "result:" $result
    fi
}

DNS_update() {
    prefix_url="https://api.godaddy.com/v1/domains/$1/records"
    # update A record
    record_update $(curl -s "https://api.ipify.org") "$prefix_url/A/$2"
    # update AAAA record
    record_update $(curl -s "https://api6.ipify.org") "$prefix_url/AAAA/$2"
}

for record in "${records[@]}"; do
    DNS_update $record
done
