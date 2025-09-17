## BACnet/IP simulation with Docker (Ubuntu) + YABE (Windows)

Prereqs: Ubuntu host on same VLAN as your Windows PC (with YABE), Docker installed.

### 1) Build the image on Ubuntu
```bash
cd bacnet-docker
sudo docker build -t bacnet .
```

### 2) Get network details on Ubuntu
```bash
IFACE=$(ip route | awk '/^default/ {print $5; exit}')
GW=$(ip route | awk '/^default/ {print $3; exit}')
SUBNET=$(ip -o -4 route show dev "$IFACE" scope link | awk 'NR==1{print $1}')
echo "IFACE=$IFACE SUBNET=$SUBNET GW=$GW"
```

### 3) Create a macvlan network on your VLAN
This gives each container its own IP on the LAN, enabling BACnet/IP broadcasts.
```bash
sudo docker network create -d macvlan \
  --subnet="$SUBNET" --gateway="$GW" \
  -o parent="$IFACE" bacnet_macvlan
```

### 4) Start devices (pick free IPs on your subnet)
Example uses 192.168.1.210–212; change as needed.
```bash
sudo docker run -d --name bacnet-200001 --network bacnet_macvlan --ip 192.168.1.210 bacnet bacserv 200001 Server-1
sudo docker run -d --name bacnet-200101 --network bacnet_macvlan --ip 192.168.1.211 bacnet bacserv 200101 HVAC-1
sudo docker run -d --name bacnet-200102 --network bacnet_macvlan --ip 192.168.1.212 bacnet bacserv 200102 TempSensors-1
```

### 5) Start chatter (setpoint and temp updates)
```bash
sudo docker run -d --name sim-200101 --network bacnet_macvlan bacnet sh -lc 'while true; do v=$(perl -e "printf(\"%.1f\",20+rand(4))"); bacwp 200101 2 0 85 16 -1 4 $v >/dev/null 2>&1; sleep 15; done'
sudo docker run -d --name sim-200102 --network bacnet_macvlan bacnet sh -lc 'while true; do for i in 0 1 2; do v=$(perl -e "printf(\"%.2f\",18+rand(8))"); bacwp 200102 2 $i 85 16 -1 4 $v >/dev/null 2>&1; done; sleep 30; done'
```

### 6) YABE (Windows, same VLAN)
- BACnet/IP V4 & V6 over UDP
- Port: BAC0
- Local endpoint: select your Windows NIC IP on this VLAN (not 127.0.0.1)
- Ensure “Send WhoIs” is checked, then Start
- Devices at your chosen IPs (e.g., 192.168.1.210/211/212) should appear; open `analogValue` 0..2 to view updates

### Troubleshooting
- Allow UDP 47808 in Windows Firewall on that NIC
- Ensure chosen container IPs are free/reachable on the LAN
- Switch port security features can block extra MACs; adjust if needed

Built with the latest BACnet stack tools: https://github.com/bacnet-stack/bacnet-stack

