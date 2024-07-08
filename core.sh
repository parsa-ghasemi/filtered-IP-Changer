#!/bin/bash


#-------------------------start functions

# telegram bot ($1=token, $2=chat_id, $3=message, $4=disable notifications)
  function telegram_message(){
    curl -s -X POST https://public-telegram-bypass.solyfarzane9040.workers.dev/bot$1/sendMessage -d chat_id=$2 -d text="$3" -d disable_notification="$4" > /dev/null
  }


# update ips
  function update_ips(){
    source settings.sh
  }



# ping ($1=ip)
  function get_ping(){

    ping=$( echo `ping -w5 $1 | grep -c 'ms'`)

   
    if [ $ping4 -ge "5" ]
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
        cf_dns_ids[$i]=$( echo $request | jq -r '.result | .['$i'] | .id' )
        cf_dns_domains[$i]=$( echo $request | jq -r '.result | .['$i'] | .name' )         
        i=$(( $i + 1 ))
      done
  }


# update cloudflare domains ip ($1=ip, $2=zone-id, $3=email, $4=key, $5=andis, $6=proxied)
  function cf_records_update(){
    cf_records_info $2 $3 $4
       curl -v -XPUT \
            --header 'Content-Type: application/json' \
            --header 'X-Auth-Email:'$3 \
            --header 'X-Auth-Key:'$4 \
            --data '{
            "content": "'$1'",
            "name": "'${cf_dns_domains[$5]}'",
            "proxied": '$6',
            "type": "A"
          }' 'https://api.cloudflare.com/client/v4/zones/'$2'/dns_records/'${cf_dns_ids[$5]}
    
    cf_records_info $2 $3 $4
    request=`echo $request | grep -c $1`

    if [ $request -ge "1" ]
    then
      message="cloudflare changed ip. - ${cf_dns_domains[$5]} - ($1)"
      telegram_message $telegram_token $telegram_chat_id "$message" '1'
    else
      message="cloudflare could not change ip. - ${cf_dns_domains[$5]} - ($1) - ($2)"
      telegram_message $telegram_token $telegram_chat_id "$message" '0'
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
        "name": "'${ac_dns_domains[$4]}'",
        "cloud": '$5',
        "upstream_https": "default",
        "ip_filter_mode": {
          "count": "single",  
          "order": "none",
          "geo_filter": "none"
        }
      }' 'https://napi.arvancloud.ir/cdn/4.0/domains/'$2'/dns-records/'${ac_dns_ids[$4]} 

    ac_records_info $2 $3
    request=`echo $request | grep -c $1`

    if [ $request -ge "1" ]
    then
      message="arvancloud changed ip. - ${ac_dns_domains[$4]} - ($1)"
      telegram_message $telegram_token $telegram_chat_id "$message" '1'
    else
      message="arvancloud could not change ip. - ${ac_dns_domains[$4]} - ($1) - ($2)"
      telegram_message $telegram_token $telegram_chat_id "$message" '0'
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


#update tunnel ip ($1=ip)
  function iran_tunnel(){
    sed -i "s/IP00/$1/g" tunnel.json
    `cp -r tunnel.json /usr/local/etc/xray/config.json`
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




ping_res=`get_ping $CURRENT_IP1`
if [ $ping_res = "1" ]
then
  message='your ip is available in iran.'
  echo "export STATUS='1'" > status.env
  echo $message | systemd-cat -t CDN-IP-changer -p info
else
  ping_res=`get_ping $CURRENT_IP1`
  if [ $ping_res = "0" ]
  then
    ping_res=`get_ping $CURRENT_IP1`
    if [ $ping_res = "0" ]
    then
      if [ -n $STATUS ]
      then
        if [ `echo $STATUS` = '0' ]
        then
        update_ips
        iran_tunnel $NEW_IP
          message='your ip changed.' 
          telegram_message $telegram_token $telegram_chat_id "$message" '1'
          printf "\nexport CURRENT_IP1='`echo $NEW_IP`' \n# `date -R`" >> ips.env
          echo "export STATUS='1'" > status.env
          echo $message | systemd-cat -t CDN-IP-changer -p info
        elif [ `echo $STATUS` = '1' ]
        then
          message='please check ip maybe is unavailable.'
          telegram_message $telegram_token $telegram_chat_id "$message" '0'
          echo "export STATUS='0'" > status.env
          echo $message | systemd-cat -t CDN-IP-changer -p warning
        fi
      else
        message='STATUS variable is not correct or is not set.'
        telegram_message $telegram_token $telegram_chat_id "$message" '0'
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
