<?php
// ipv4示例 URL：http://your.php.site/gdns.php?hostname=host.your.domain&myip=99.28.150.4
// ipv6示例 URL：http://your.php.site/gdns.php?hostname=host.your.domain&myip=2408:841b:221b:6b:f89a:78c4:1912:3&type=ipv6

// godaddy token
$GD_Key = "your_godaddy_key";
$GD_Secret = "your_godaddy_secret";
$logFilePath = "logs/gdns_log"; // If the logFilePath is '', no log will output

function glog($message)
{
    global $logFilePath;
    if ($logFilePath == '')
        return;
    $logFile = "$logFilePath" . gmdate('Ymd') . ".txt";
    $currentDateTime = gmdate('Y-m-d H:i:s');
    file_put_contents(
        $logFile,
        "== $currentDateTime ==========================" . PHP_EOL . $message . PHP_EOL,
        FILE_APPEND
    );
}

if (isset($_GET['hostname'])) {
    $fullDomain = explode(".", $_GET['hostname'], 2);
    $hostname = $fullDomain[0];
    $domain = $fullDomain[1];
}

if (isset($_GET['type']) && $_GET['type'] == 'ipv6') {
    $ipv6 = true;
    $type = 'AAAA';
} else {
    $ipv6 = false;
    $type = 'A';
}

if (isset($_GET['myip'])) {
    $myip = $_GET['myip'];
    $ip_valid = $ipv6
        ? filter_var($myip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) !== false
        : filter_var($myip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false;
}
if (!$ip_valid) {
    glog("IP invalid : $myip");
    exit("IP地址不合法");
}

$auth_header = "Authorization: sso-key $GD_Key:$GD_Secret";
$url = "https://api.godaddy.com/v1/domains/$domain/records/$type/$hostname";

function sendRequest($url, $data, $method)
{
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    global $auth_header;
    if ($method == 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt(
            $ch,
            CURLOPT_HTTPHEADER,
            array(
                $auth_header,
                'Content-Type: application/json',
                'Content-Length: ' . strlen(json_encode($data))
            )
        );
    } else {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "GET");
        curl_setopt($ch, CURLOPT_HTTPHEADER, array($auth_header));
    }

    $response = curl_exec($ch);
    if ($response === false) {
        glog("visiting godaddy error: " . curl_error($ch));
        exit("访问GoDaddy错误: " . curl_error($ch));
    }
    curl_close($ch);
    return $response;
}

// get godaddy IP
$response = sendRequest($url, null, 'GET');
$data = json_decode($response, true);
if ($data === null) {
    glog("recive error");
    exit("GoDaddy返回数据出错");
} else {
    $GDIP = $data[0]["data"];
}

glog("$hostname.$domain myip:$myip GDIP:$GDIP");

if ($myip != $GDIP) {
    $record = array('data' => $myip, 'ttl' => 1800);
    $response = sendRequest($url, array($record), "PUT");
    echo "updated";
    glog("updated");
} else {
    echo "OK";
}

?>