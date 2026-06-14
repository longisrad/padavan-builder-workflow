#!/bin/sh

# 1. FIREWALL CÔ LẬP
iptables -A INPUT -i $WAN_IF -s 192.168.1.1 -j ACCEPT
iptables -A INPUT -i $WAN_IF -s 192.168.1.0/24 -j DROP
iptables -A FORWARD -i $WAN_IF -s 192.168.1.0/24 -d 192.168.123.0/24 -j DROP
logger -t "【BẢO MẬT】" "Đã cô lập dải mạng 192.168.1.x!"

# 2. BIẾN CẤU HÌNH
WAN_IF=$(nvram get wan0_ifname)
[ -z "$WAN_IF" ] && WAN_IF="eth3"
DOWNLINK=220000
UPLINK=160000

# 3. CẤU HÌNH QoS
tc qdisc del dev $WAN_IF root 2>/dev/null
tc qdisc del dev $WAN_IF ingress 2>/dev/null
tc qdisc del dev ifb0 root 2>/dev/null
modprobe ifb numifbs=1
ip link set dev ifb0 up

tc qdisc add dev $WAN_IF root handle 1: htb default 10
tc class add dev $WAN_IF parent 1: classid 1:1 htb rate ${UPLINK}kbit
tc class add dev $WAN_IF parent 1:1 classid 1:10 htb rate ${UPLINK}kbit ceil ${UPLINK}kbit
tc qdisc add dev $WAN_IF parent 1:10 handle 10: fq_codel limit 1000 target 5ms interval 100ms

tc qdisc add dev $WAN_IF handle ffff: ingress
tc filter add dev $WAN_IF parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ifb0
tc qdisc add dev ifb0 root handle 1: htb default 10
tc class add dev ifb0 parent 1: classid 1:1 htb rate ${DOWNLINK}kbit
tc class add dev ifb0 parent 1:1 classid 1:10 htb rate ${DOWNLINK}kbit ceil ${DOWNLINK}kbit
tc qdisc add dev ifb0 parent 1:10 handle 10: fq_codel limit 1000 target 5ms interval 100ms

#=========================================================
# LUỒNG CAO CẤP V17: HOÀN THIỆN ĐỒNG BỘ CACHE 8192 & BLOCK ADS
# =========================================================
logger -t "【MOD HỆ THỐNG】" "Kích hoạt luồng tối ưu bộ nhớ & chặn quảng cáo V17..."

 # 1. Chờ hệ thống ổn định hoàn toàn
sleep 30

# 2. Xóa sạch các file phụ cấu hình cache cũ để tránh xung đột lặp từ khóa
rm -rf /etc/storage/dnsmasq/dnsmasq.d/*
rm -f /etc/storage/dnsmasq/abpvn.hosts

# 3. Tải và xử lý file chặn quảng cáo
curl -kLs --connect-timeout 6 -m 20 "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts" > /tmp/hosts_vn
curl -kLs --connect-timeout 6 -m 20 "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt" > /tmp/hosts_intl

if [ -s /tmp/hosts_vn ] && [ -s /tmp/hosts_intl ]; then
    cat /tmp/hosts_vn /tmp/hosts_intl | sed 's/\r//g; /^#/d; /^!/d; /^$/d; /^[[:space:]]*$/d' | sed 's/127.0.0.1/0.0.0.0/g' | sort -u > /etc/storage/dnsmasq/abpvn.hosts
    TOTAL_LINES=$(wc -l < /etc/storage/dnsmasq/abpvn.hosts)
    logger -t "【MOD CHẶN QC】" "Đã nạp thành công $TOTAL_LINES dòng chặn QC sạch."
        
# Chỉ nạp chỉ thị cấu hình nạp file hosts phụ vào đây
    echo "addn-hosts=/etc/storage/dnsmasq/abpvn.hosts" > /etc/storage/dnsmasq/dnsmasq.d/hosts_add.conf
else
    logger -t "【MOD CHẶN QC】" "Không có mạng hoặc timeout, bỏ qua tải file QC."
fi
rm -f /tmp/hosts_vn /tmp/hosts_intl

# 4. Giết toàn bộ dnsmasq cũ để giành quyền kiểm soát tối cao
killall -9 dnsmasq dnsmasq-dhcp 2>/dev/null
sleep 1

# 5. Khởi động dnsmasq thông qua cấu hình hệ thống với bộ đệm cache khủng và hàng đợi 500
if [ -f /tmp/dnsmasq.conf ]; then
    sed -i '/cache-size/d' /tmp/dnsmasq.conf 2>/dev/null
    /usr/sbin/dnsmasq --conf-file=/tmp/dnsmasq.conf --cache-size=8192 --dns-forward-max=500
else
    /usr/sbin/dnsmasq --conf-file=/etc/storage/dnsmasq/dnsmasq.conf --cache-size=8192 --dns-forward-max=500
fi

# 6. Ép đọc lại cấu hình để nạp file hosts quảng cáo vừa tạo
killall -HUP dnsmasq
logger -t "【FIX CACHE】" "Đã tối ưu DNSmasq chạy với cache-size=8192 & đã nạp Ads."

# 7. Đồng bộ lưu vào Flash an toàn
/sbin/mtd_storage.sh save
logger -t "【MOD HỆ THỐNG】" "Đồng bộ cấu hình Flash hoàn tất!"
