## Initialization:


### 1. install requirements:
#### 1. install jq.
```bash script
sudo apt install jq -y
```



#### 2. install dokodemodoor tunnel.
```bash script
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
sudo systemctl start xray
```





### 2. install script
```bash 
wget https://github.com/parsa-ghasemi/filtered-IP-Changer/archive/refs/tags/v2.0.0.tar.gz
tar xvzf v2.0.0.tar.gz
rm -r v2.0.0.tar.gz
cd filtered-IP-Changer-2.0.0

```





### 3. set tokens
```bash script
nano settings.sh
```
set your cloudflare information in `cf_records_update` and set arvancloud in `ac_records_update`.

#### andis parameter
<img src="https://github.com/parsa-ghasemi/CDN-DNS-ip-changer/assets/105058611/9039f4f1-8309-45c2-b56a-5db3082a0d4c" width="450" >
<img src="https://github.com/parsa-ghasemi/CDN-DNS-ip-changer/assets/105058611/1d3a6705-e6db-4968-a370-4ab9c1cf6bd0" width="450" >



### 4. set telegram bot
```bash script
nano tel.env
```



### 5. set ips
```bash script
nano ips.env
```
enter $NEW_IP and $CURRENT_IP1 with your IPs.





## run script:
```bash script
sudo chmod +x start.sh
bash start.sh
```



## cronjob
you can set cronjob for auto update IP, if the IP doesn't ping then changed DNS IP in your all services.
</br></br>
```
*/5 * * * * cd /the/file/location/filtered-IP-Changer/ && /bin/bash start.sh
```



## log
you can check log with this.
```
journalctl -ef -t filtered-IP-Changer
```
