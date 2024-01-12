#!/bin/bash
location='/home/parsa/Desktop/CDN-DNS-ip-changer'
cd $location

source status.env
source ips.env
bash server.sh