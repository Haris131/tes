#!/bin/bash
clear
 injek (){
host=$(grep host= config.txt|awk -F "=" '{print $2}')
port=$(grep port= config.txt|awk -F "=" '{print $2}')
sni=$(grep sni= config.txt|awk -F "=" '{print $2}')
echo "[ssh]
client = yes
accept = localhost:8780
connect = $host:$port
sni = $sni" > /tmp/stunnel.conf
stunnel /tmp/stunnel.conf
}
 routing (){
host=$(grep host= config.txt|awk -F "=" '{print $2}')
ifaces=$(ip r|grep default|awk '{print $3}')
if [ ! -f $(echo $ifaces|awk -F "." '{print $2}') ]; then
 if [ $(echo $ifaces|awk -F "." '{print $4}'|wc -c) != "2" ]; then
  ipg=$(ip r|grep default|awk '{print $3}');ifaces=$(ip r|grep default|awk '{print $5}')
  ip route add $host dev $ifaces via $ipg 2>/dev/null
  ip route add 8.8.8.8 $ifaces via $ipg 2>/dev/null
  route del default;ip route add default dev $ifaces via $ipg metric 1 2>/dev/null
 else
  type=gw;route add $host $type $ifaces 2>/dev/null
  route add 8.8.8.8 $type $ifaces 2>/dev/null
  route del default;route add default $type $ifaces metric 1 2>/dev/null
  fi
else
 type=dev;route add $host $type $ifaces 2>/dev/null
 route add 8.8.8.8 $type $ifaces 2>/dev/null
 route del default;route add default $type $ifaces metric 1 2>/dev/null
fi
}
 flushx () {
echo -e "{$(date +%M:%S)} Membersihkan sisa sisa, Tunggu...."
killall -q sshpass vpn stunnel openvpn autorekonek badvpn-tun2socks
kill $(ps w|grep badvpn|grep tun|awk "NR==1"|awk '{print $1}') 2>/dev/null
host=$(grep host= config.txt|awk -F "=" '{print $2}')
route del $host 2>/dev/null;route del 8.8.8.8 2>/dev/null
}
 start () {
#########################
pudp=$(grep pudp= config.txt 2>/dev/null|awk -F "=" '{print $2}')
sni=$(grep sni= config.txt 2>/dev/null|awk -F "=" '{print $2}')
if [ -f $(badvpn-tun2socks -version 2>/dev/null|awk '{print $1}'|awk "NR==1") ]; then
 echo "Paket badvpn-tun2socks belom terinstall. install dulu!"
 echo "Gunakan Koneksi normal dan"
 echo "Installer: https://github.com/vitoharhari/xderm-mini";exit
fi
if [ -f $(ls /usr/bin/stunnel 2>/dev/null|awk -F '/' '{print $4}'|awk "NR==1") ]; then
 echo "Paket stunnel belom terinstall. install dulu!"
 echo "Gunakan Koneksi normal dan"
 echo "Ketik: opkg update && opkg install stunnel";exit
fi
host=$(grep host= config.txt|awk -F "=" '{print $2}')
if [ -f $host ]; then
 echo -e "{$(date +%M:%S)} Config belom disetting !!";sleep 1;exit 2>/dev/null
fi
port=$(grep port= config.txt|awk -F "=" '{print $2}')
user=$(grep user= config.txt|awk -F "=" '{print $2}')
pass=$(grep pass= config.txt|awk -F "=" '{print $2}')
#########################
flushx;killall -q timeout;ifaces=$(ip r|grep default|awk '{print $3}');routing
echo "#!/bin/bash
sleep 10;killall -q openssl" > /tmp/timeou;chmod +x /tmp/timeou;./tmp/timeou &
echo -e "{$(date +%M:%S)} Menguji bug SNI (openssl).. "
 if [ -f $(echo "exit"|openssl 2>/dev/null) ]; then
echo -e " tidak ada paket openssl, install dulu!"
echo -e " Gunakan Koneksi normal dan"
echo -e " opkg update && opkg install openssl-util";exit
 fi
sleep 2
supp=$(echo "QUIT"|openssl s_client -connect 8.8.8.8:443 -servername $sni 2>/dev/null|grep supp|awk '{print $4}')
 if [ ! -f $supp ]; then
echo "OK"
else
killall -q openssl timeou;./tmp/timeou &
 supp=$(echo "QUIT"|openssl s_client -connect 8.8.8.8:443 -servername $sni 2>/dev/null|grep supp|awk '{print $4}')
   if [ ! -f $supp ]; then
echo "OK"
 else
killall -q openssl timeou
echo "Closed!";exit
   fi 
 fi
host=$(grep host= config.txt|awk -F "=" '{print $2}')
echo -ne "{$(date +%M:%S)} Menjalankan Inject "
killall -q openssl timeou;rm -rf /tmp/timeou
injek;echo "[stunnel]"
echo "##############################################"
echo "  Host: $host"
echo "  Port: $port"
echo "  User: $user"
echo "  Pass: ********"
echo "  Port UDPgw: $pudp"
echo "##############################################"
echo -e "{$(date +%M:%S)} Menjalankan SSH (di latarbelakang)...."
rm -rf /root/.ssh/known_hosts* 2>/dev/null
sshpass -p "$pass" ssh -oTCPKeepAlive=yes -oServerAliveInterval=180 -oServerAliveCountMax=2 -oStrictHostKeyChecking=no -CND 127.0.0.1:1080 -p 8780 $user@localhost &
sleep 1;n=0;echo -ne "{$(date +%M:%S)} Menguji Koneksi... "
while [ $n != 7 ]; do
 if [ ! -f $(grep Permission 2>/dev/null|awk "NR==1"|awk '{print $4}') ]; then
     echo -e "\e[31;1mNot Connect!\e[0m"
     echo -e "\e[33;1m{$(date +%M:%S)}\e[0m \e[36;3mUsername/Password Salah/Kadaluarsa.\e[0m"
     flushx;echo -e "{$(date +%M:%S)} Berhenti.";exit
 fi
r=$(curl -m4 88.198.46.60 -w "%{http_code}" --proxy socks5://127.0.0.1:1080 -s -o /dev/null|head -c2)
  if [ $r -eq 30 ]; then
  echo -e "\e[32;1mHTTP/1.1 $r OK\e[0m";break
  fi
konek=n
done
 if [ $konek != y ]; then
echo -e "\e[31;1mNot Connect!\e[0m"
flushx;echo -e "\e[33;1m{$(date +%M:%S)}\e[0m Berhenti.\n";exit
 fi
############################################################
echo -e "{$(date +%M:%S)} Menjalankan Badvpn-tun2socks...."
pudp=$(grep pudp config.txt|awk -F "=" '{print $2}')
badvpn-tun2socks --tundev tun0 --netif-ipaddr 10.0.0.2 --netif-netmask 255.255.255.0 --socks-server-addr 127.0.0.1:1080 --udpgw-remote-server-addr 127.0.0.1:$pudp --udpgw-transparent-dns --loglevel 0 &;sleep 2
ifconfig tun0 10.0.0.1 netmask 255.255.255.0 2>/dev/null
echo -e "{$(date +%M:%S)} Menggunakan $ifaces sebagai Pusat sumber."
echo -e "{$(date +%M:%S)} Routing Host, IP Gateway dan dns.."
route add default gw 10.0.0.2 metric 0 2>/dev/null
if [ ! -f $(cat config/dns 2>/dev/null|awk -F '=' '{print $2}') ]; then
 if [ -f $(grep -n 8.8.8.8 /etc/config/dhcp 2>/dev/null|awk -F ":" '{print $1}') ]; then
 sed -i "15 i\        list server '8.8.8.8#53'" /etc/config/dhcp 2>/dev/null
 fi
fi
echo -e "{$(date +%M:%S)} Menjalankan rekonek otomatis..."
echo "#!/bin/bash
while true; do
r=\$(curl -m75 google.com -w \"%{http_code}\" --proxy socks5://127.0.0.1:1080 -s -o /dev/null|head -c2);sleep 2
  if [ \$r != 30 ]; then
killall -q sshpass;rm -rf /root/.ssh/known_hosts*
sshpass -p \"$pass\" ssh -oTCPKeepAlive=yes -oServerAliveInterval=180 -oServerAliveCountMax=2 -oStrictHostKeyChecking=no -CND 127.0.0.1:1080 -p 8780 $user@localhost &;sleep 10
  fi
sleep 1
done" > /tmp/autorekonek;cd /tmp;chmod +x autorekonek
./autorekonek &;sleep 2
fi
echo -e "{$(date +%M:%S)} Selesai.";exit
}
case $1 in
 "start")
 start
;;
 "stop")
 flushx
;;
esac
echo -e "\e[38;3m stun start\e[0m \e[34;1m(memulai injek)\e[0m"
echo -e "\e[38;3m stun stop\e[0m \e[34;1m(menghentikan injek)\e[0m"
