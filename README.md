## Initialization:


### 1. install jq:
```bash script
sudo apt update && sudo apt upgrade
sudo apt install jq -y
```





### 2. install script
```bash 
wget https://github.com/parsa-ghasemi/CDN-DNS-ip-changer/archive/refs/tags/v1.4.1.tar.gz
tar xvzf v1.4.tar.gz
rm -r v1.4.tar.gz
cd CDN-DNS-ip-changer-1.4

```





### 3. set tokens
```bash script
nano server.sh
```
set your cloudflare information in `cf_records_update` and set arvancloud in `ac_records_update`.
</br>
get free API token of [siterelic.com](siterelic.com) and set in `get_ping`.
</br>
if you use this for vpn-server, you can use `iran_tunnel` for set your tunnel config.
#### andis parameter
<img src="https://github.com/parsa-ghasemi/CDN-DNS-ip-changer/assets/105058611/9039f4f1-8309-45c2-b56a-5db3082a0d4c" width="450" >
<img src="https://github.com/parsa-ghasemi/CDN-DNS-ip-changer/assets/105058611/1d3a6705-e6db-4968-a370-4ab9c1cf6bd0" width="450" >

</br></br>
```bash script
get_ping $CURRENT_IP1 'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx'`
# ($1=ip, $2=siterelic token)
cf_records_update $NEW_IP 'xxxxxxxxxxxxxxxxxxxxxxxxxx' 'xxxxxxx@xxxxx.xxx' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'x x'
# ($1=ip, $2=zone-id, $3=email, $4=key, $5=andis)
ac_records_update $NEW_IP 'xxxxxxxx.xxx' 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx' 'x x x'
# ($1=ip, $2=domain, $3=key, $4=andis)
iran_tunnel $NEW_IP '/address/of/your/tunnel/service/config.txt'
# ($1=ip, $2=config-address) and set tunnel config in main function
```




### 4. set ips
```bash script
nano ips.env
```
enter $NEW_IP, $CURRENT_IP1 with your IPs and, save & exit file with `control + y` & `control + x`.






### 5. set location
```bash script
nano start.sh
```
set the files locations in `$location`




## run script:
```bash script
sudo chmod +x start.sh
bash start.sh
```



## cronjob
you can set cronjob for auto update IP, if the IP doesn't ping then changed DNS IP in your all services
</br></br>
```
*/5 * * * * /bin/bash /the/file/location/CDN-DNS-ip-changer/start.sh
```



## log
you can check log with this
```
journalctl -ef -t CDN-IP-changer
```
