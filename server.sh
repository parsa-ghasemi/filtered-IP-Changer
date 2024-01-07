#!/bin/bash




# that ip you want to set
ip='1.1.1.1'







#-------------------------start functions

# global ping ($1=ip)
function get_ping(){
  request=$(curl -v -H "Accept: application/json" \
  'https://check-host.net/check-ping?host='$1'&node=pl1.node.check-host.net&node=us3.node.check-host.net&node=jp1.node.check-host.net&node=fr2.node.check-host.net' | jq -r '.request_id')

  request=$(curl -v -H "Accept: application/json" \
  https://check-host.net/check-result/$request)

  ping1=`echo $request | jq -r .'"jp1.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping2=`echo $request | jq -r .'"pl1.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping3=`echo $request | jq -r .'"us3.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping4=`echo $request | jq -r .'"fr2.node.check-host.net" | .[0] | .[0] | .[0]'`

  if [ $ping1 = "OK" -o $ping2 = "OK" -o $ping3 = "OK" -o $ping4 = "OK" ]
  then
    echo '1'
  else
    echo '0'
  fi
}


# iran ping ($1=ip)
function get_iran_ping(){
  request=$(curl -v -H "Accept: application/json" \
  'https://check-host.net/check-ping?host='$1'&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net' | jq -r '.request_id')

  request=$(curl -v -H "Accept: application/json" \
  https://check-host.net/check-result/$request)

  ping1=`echo $request | jq -r .'"ir1.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping2=`echo $request | jq -r .'"ir3.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping3=`echo $request | jq -r .'"ir5.node.check-host.net" | .[0] | .[0] | .[0]'`
  ping4=`echo $request | jq -r .'"ir6.node.check-host.net" | .[0] | .[0] | .[0]'`

  if [ $ping1 = "OK" -a $ping2 = "OK" -a $ping3 = "OK" -a $ping4 = "OK" ]
  then
    echo '1'
  else
    echo '0'
  fi
}


# get zone information of cloudflare ($1=zone-id, $2=email, $3=key)
  function cf_records_info(){
    request=$(curl -v --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$1/dns_records \
    --header 'Content-Type: application/json' \
    --header 'X-Auth-Email:'$2 \
    --header 'X-Auth-Key:'$3)
    
    cf_domains_count=$( echo $request | jq -r '.result_info | .total_count' )
    
    local i=0
    while [ $i -le $(( $cf_domains_count - 1 )) ]
      do
        cf_dns_ids+=($(echo $request | jq -r '.result | .['$i'] | .id' ))
        cf_dns_domains+=($(echo $request | jq -r '.result | .['$i'] | .name' ))        
        i=$(( $i + 1 ))
      done
  }


# update cloudflare domains ip ($1=ip, $2=zone-id, $3=email, $4=key, $5=andis)
  function cf_records_update(){
    cf_records_info $2 $3 $4
    for i in $5
      do
       curl -v --request PUT \
            --url https://api.cloudflare.com/client/v4/zones/$2/dns_records/${cf_dns_ids[$i]} \
            --header 'Content-Type: application/json' \
            --header 'X-Auth-Email:'$3 \
            --header 'X-Auth-Key:'$4 \
            --data '{
            "content": "'$ip'",
            "name": "'${cf_dns_domains[$i]}'",
            "proxied": true,
            "type": "A"
          }'
        i=$(( $i + 1 ))
      done      
      cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
------------------------------------ cloudflare finished. ---------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END
  }


# get zone information 0f arvancloud ($1=domain, $2=key)
  function ac_records_info(){
    request=$(curl -v --location --request GET 'https://napi.arvancloud.ir/cdn/4.0/domains/'$2'/dns-records' \
    --header 'Accept: application/json' \
    --header "Authorization:apikey $3")

    ac_domains_count=$((( $( echo $request | jq -r '.meta | .total' ) - 2 )))

    i=0
    while [ $i -le $(( $ac_domains_count - 1 )) ]
      do
        ac_dns_ids[$i]=$(echo $request | jq -r '.data | .['$i'] | .id' )
        ac_dns_domains[$i]=$(echo $request | jq -r '.data | .['$i'] | .name')
        i=$(( $i + 1 ))
      done
  }


# update arvancloud domains ip ($1=ip, $2=domain, $3=key, $4=andis)
  function ac_records_update(){
    ac_records_info $2 $3
    for i in $4
      do
        curl -v -XPUT \
        --header "Authorization:apikey $3" \
        --header 'Accept: application/json' \
        --header "Content-type: application/json" \
        --data '{
          "value": [
            {
              "ip": "'$ip'",
              "port": null, 
              "weight": null,
              "country": "IR"
            }           
          ],
          "type": "a",
          "name": "'${ac_dns_domains[$i]}'",
          "cloud": true,
          "upstream_https": "default",
          "ip_filter_mode": {
            "count": "single",  
            "order": "none",
            "geo_filter": "none"
          }
        }' 'https://napi.arvancloud.ir/cdn/4.0/domains/'$2'/dns-records/'${ac_dns_ids[$i]}   

        i=$(( $i + 1 ))
      done 
      cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
------------------------------------ arvancloud finished. ---------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END

  }

#update tunnel ip ($1=ip, $2=config-address)
  function iran_tunnel(){
    cat <<END > $2
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": null,
      "port": 80,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "$1",
        "followRedirect": false,
        "network": "tcp,udp",
        "network": "tcp,udp",
        "port": 80
      },
      "tag": "inbound-80"
    },
    {
      "listen": null,
      "port": 8443,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "$1",
        "followRedirect": false,
        "network": "tcp,udp",
        "port": 8443
      },
      "tag": "inbound-8443"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}

END

      `sudo systemctl restart xray`
  
      cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
------------------------------------ tunnel finished. -------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END
  }
#------------------------- end functions



cf_records_update $ip 'xxxxxxxxxxxxxxxxxxxxxxxxxx' 'xxxxxxx@xxxxx.xxx' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'x x'
ac_records_update $ip 'xxxxxxxx.xxx' 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx' 'x x x'
iran_tunnel $ip '/address/of/your/tunnel/service/config.txt'




