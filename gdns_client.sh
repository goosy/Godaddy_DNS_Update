records=(
    "name1.dns.server"
    "name2.dns.server"
)

DNS_update() {
    prefix_url="http://your.web.service/gdns.php?hostname=$1"
    # update A record
    myip=$(curl -s "https://api.ipify.org")
    url="$prefix_url&myip=$myip"
    ret=$(curl -s -X GET "$url")
    echo "$url $ret"
    # update AAAA record
    myip=$(curl -s "https://api6.ipify.org")
    url="$prefix_url&myip=$myip&type=ipv6"
    ret=$(curl -s -X GET "$url")
    echo "$url $ret"
}

for record in "${records[@]}"; do
    DNS_update $record
done
