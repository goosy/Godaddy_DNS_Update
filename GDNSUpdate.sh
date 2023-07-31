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
IPV4_reg='(([0-9]{1,3}\.){3}[0-9]{1,3})'
IPV6_reg='(([0-9a-f]{1,4}:){7}[0-9a-f]{1,4})'

record_update() {
    myIP="$3"
    url=''
    if [[ "$myIP" =~ ^$IPV4_reg$ ]]; then
        url="https://api.godaddy.com/v1/domains/$1/records/A/$2"
        reg="\b$IPV4_reg\b"
    fi
    if [[ "$myIP" =~ ^$IPV6_reg$ ]]; then
        url="https://api.godaddy.com/v1/domains/$1/records/AAAA/$2"
        reg="\b$IPV6_reg\b"
    fi
    if [ "$url" = '' ]; then
        echo "IP is warning"
        return 1 # return value 1 on failure
    fi
    dns_data=$(curl -s -X GET -H "$auth_header" "$url")
    # echo $dns_data
    GDIP=$(echo $dns_data | grep -oE $reg)
    # echo "$myIP" "$GDIP" "$url"
    if [ "$GDIP" != "$myIP" ] && [ "$myIP" != "" ]; then
        # echo "Ips are not equal"
        req_data='[{"data":"'$myIP'","ttl":600}]'
        # echo "req_data:" "$req_data"
        result=$(curl -i -s -X PUT "$url" \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            -d $req_data
        )
        # echo "result:" "$result"
    fi
}

DNS_update() {
    prefix_url="https://api.godaddy.com/v1/domains/$1/records"
    # update A record
    record_update $1 $2 $(curl -s "https://api.ipify.org")
    # update AAAA record
    record_update $1 $2 $(curl -s "https://api6.ipify.org")
}

for record in "${records[@]}"; do
    DNS_update $record
done
