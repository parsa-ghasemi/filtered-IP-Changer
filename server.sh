#!/bin/bash

telegram_token='xxxxxxx:xxxxxxxxxxxxxxxxxxxxxxxx'
telegram_chat_id=xxxxxxxx

#-------------------------start functions

# global ping ($1=token, $2=chat_id, $3=message)
  function telegram_message(){
    curl -s -X POST https://public-telegram-bypass.solyfarzane9040.workers.dev/bot$1/sendMessage -d chat_id=$2 -d text="$3" > /dev/null
  }


# update ips
  function update_ips(){
    cf_records_update $NEW_IP 'xxxxxxxxxxxxxxxxxxxxxxxxxx' 'xxxxxxx@xxxxx.xxx' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'x x' 'true'
    ac_records_update $NEW_IP 'xxxxxxxx.xxx' 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx' 'x x x' 'true'
  }


# global ping ($1=ip, $2=siterelic token)
  function get_ping(){
    request=$(curl -v --header "Accept: application/json" \
    'https://check-host.net/check-ping?host='$1'&node=pl1.node.check-host.net&node=us3.node.check-host.net&node=fr2.node.check-host.net' | jq -r '.request_id')

    request=$(curl -v --header "Accept: application/json" \
    https://check-host.net/check-result/$request)

    ping1=`echo $request | jq -r .'"pl1.node.check-host.net" | .[0] | .[0] | .[0]'`
    ping2=`echo $request | jq -r .'"us3.node.check-host.net" | .[0] | .[0] | .[0]'`
    ping3=`echo $request | jq -r .'"fr2.node.check-host.net" | .[0] | .[0] | .[0]'`

    if [ $ping1 = "OK" -o $ping2 = "OK" -o $ping3 = "OK" ]
    then
      echo '1'
    else
      request2=$(curl --location --request POST 'https://api.siterelic.com/ping' \
      --header 'x-api-key:'$2 \
      --header 'Content-Type: application/json' \
      --data-raw '{ "url": "'$1'" }')

      ping5=`echo $request2 | jq -r .'"data" | ."avg"' | cut -b 3 `

      if [ -n $ping5 ]
      then
        echo '1'
      else
        echo '0'
      fi
    fi
  }


# iran ping ($1=ip)
  function get_iran_ping(){
    request=$(curl -v --header "Accept: application/json" \
    'https://check-host.net/check-ping?host='$1'&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net' | jq -r '.request_id')

    request=$(curl -v --header "Accept: application/json" \
    https://check-host.net/check-result/$request)

    ping1=`echo $request | jq -r .'"ir1.node.check-host.net" | .[0] | .[0] | .[0]'`
    ping2=`echo $request | jq -r .'"ir3.node.check-host.net" | .[0] | .[0] | .[0]'`
    ping3=`echo $request | jq -r .'"ir5.node.check-host.net" | .[0] | .[0] | .[0]'`
    ping4=`echo $request | jq -r .'"ir6.node.check-host.net" | .[0] | .[0] | .[0]'`

    if [ -n $ping1 -a -n $ping2 ]
    then
      if [ $ping1 = "OK" -a $ping2 = "OK" -a $ping3 = "OK" -a $ping4 = "OK" ]
      then
        echo '1'
      else
        echo '0'
      fi
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
        cf_dns_ids[$i]=$( echo $request | jq -r '.result | .['$i'] | .id' )
        cf_dns_domains[$i]=$( echo $request | jq -r '.result | .['$i'] | .name' )         
        i=$(( $i + 1 ))
      done
  }


# update cloudflare domains ip ($1=ip, $2=zone-id, $3=email, $4=key, $5=andis, $6=proxied)
  function cf_records_update(){
    cf_records_info $2 $3 $4
    for i in $5
      do
       curl -v -XPUT \
            --header 'Content-Type: application/json' \
            --header 'X-Auth-Email:'$3 \
            --header 'X-Auth-Key:'$4 \
            --data '{
            "content": "'$1'",
            "name": "'${cf_dns_domains[$i]}'",
            "proxied": '$6',
            "type": "A"
          }' 'https://api.cloudflare.com/client/v4/zones/'$2'/dns_records/'${cf_dns_ids[$i]}
        i=$(( $i + 1 ))
      done      
    cf_records_info $2 $3 $4
    request=`echo $request | grep -c $1`

    if [ $request -ge "1" ]
    then
      message='cloudflare changed ip.'
    else
      message="cloudflare could not change ip. ($2)"
      telegram_message $telegram_token $telegram_chat_id "$message"
    fi
    cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------- $message ---------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END
  }


# get zone information 0f arvancloud ($1=domain, $2=key)
  function ac_records_info(){
    request=$(curl -v --location --request GET 'https://napi.arvancloud.ir/cdn/4.0/domains/'$1'/dns-records' \
    --header 'Accept: application/json' \
    --header 'Authorization:apikey '$2)

    ac_domains_count=$((( $( echo $request | jq -r '.meta | .total' ) - 2 )))

    i=0
    while [ $i -le $(( $ac_domains_count - 1 )) ]
      do
        ac_dns_ids[$i]=$( echo $request | jq -r '.data | .['$i'] | .id' )
        ac_dns_domains[$i]=$( echo $request | jq -r '.data | .['$i'] | .name')
        i=$(( $i + 1 ))
      done
  }


# update arvancloud domains ip ($1=ip, $2=domain, $3=key, $4=andis, $5=cloud)
  function ac_records_update(){
    ac_records_info $2 $3
    for i in $4
      do
        curl -v -XPUT \
        --header 'Authorization:apikey '$3 \
        --header 'Accept: application/json' \
        --header "Content-type: application/json" \
        --data '{
          "value": [
            {
              "ip": "'$1'",
              "port": null, 
              "weight": null,
              "country": "IR"
            }           
          ],
          "type": "a",
          "name": "'${ac_dns_domains[$i]}'",
          "cloud": '$5',
          "upstream_https": "default",
          "ip_filter_mode": {
            "count": "single",  
            "order": "none",
            "geo_filter": "none"
          }
        }' 'https://napi.arvancloud.ir/cdn/4.0/domains/'$2'/dns-records/'${ac_dns_ids[$i]}   

        i=$(( $i + 1 ))
      done

    ac_records_info $2 $3
    request=`echo $request | grep -c $1`

    if [ $request -ge "1" ]
    then
      message='arvancloud changed ip.'
    else
      message="arvancloud could not change ip. ($2)"
      telegram_message $telegram_token $telegram_chat_id "$message"
    fi
    cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------- $message ---------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END

  }


#update tunnel ip ($1=ip, $2=config-address)
  function iran_tunnel(){
    cat <<END > $2


    'enter the tunnel config settings here and your can use $1 for ip'


END

    `sudo systemctl restart xray`
  
    cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------- tunnel config changed. ---------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END
  }


#------------------------- end functions



if [ -n $CURRENT_IP1 ]
then
  ping_res=`get_ping $CURRENT_IP1 'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx'`
  if [ $ping_res = "1" ]
  then
    ping_iran_res=`get_iran_ping $CURRENT_IP1`
    if [ $ping_iran_res = "1" ]
    then
      message='your ip is available in iran.'
      echo "export STATUS='1'" > status.env
      echo $message | systemd-cat -t CDN-IP-changer -p info
    else
      ping_iran_res=`get_iran_ping $CURRENT_IP1`
      if [ $ping_iran_res = "0" ]
      then
        ping_iran_res=`get_iran_ping $CURRENT_IP1`
        if [ $ping_iran_res = "0" ]
        then
          if [ -n $STATUS ]
          then
            if [ `echo $STATUS` = '0' ]
            then
  #------------------------------------ set this values
           update_ips
           iran_tunnel $NEW_IP '/address/of/your/tunnel/service/config.txt'
  #----------------------------------------------------
              message='your ip changed.' 
              telegram_message $telegram_token $telegram_chat_id "$message"
              printf "\nexport CURRENT_IP1='`echo $NEW_IP`' \n# `date -R`" >> ips.env
              echo "export STATUS='1'" > status.env
              echo $message | systemd-cat -t CDN-IP-changer -p info
            elif [ `echo $STATUS` = '1' ]
            then
              message='please check ip maybe is unavailable.'
              telegram_message $telegram_token $telegram_chat_id "$message"
              echo "export STATUS='0'" > status.env
              echo $message | systemd-cat -t CDN-IP-changer -p warning
            fi
          else
            message='STATUS variable is not correct or is not set.'
            telegram_message $telegram_token $telegram_chat_id "$message"
            echo "export STATUS='1'" > status.env
            echo $message | systemd-cat -t CDN-IP-changer -p warning
          fi
        else
        message='your ip is available in iran.'
        echo "export STATUS='1'" > status.env
        echo $message | systemd-cat -t CDN-IP-changer -p info
        fi
      else
        message='your ip is available in iran.'
        echo "export STATUS='1'" > status.env
        echo $message | systemd-cat -t CDN-IP-changer -p info
      fi
    fi
  else
    message='your ip is not available at all.'
    telegram_message $telegram_token $telegram_chat_id "$message"
    echo "export STATUS='1'" > status.env
    echo $message | systemd-cat -t CDN-IP-changer -p error
  fi
else
  message='enter current ip in ips.env file'
  telegram_message $telegram_token $telegram_chat_id "$message"
  echo $message | systemd-cat -t CDN-IP-changer -p warning
fi
cat << END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------- $message ---------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
END
bash
