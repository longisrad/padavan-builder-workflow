# BẢO MẬT CÔ LẬP MẠNG NỘI BỘ KHỎI LỚP WAN 192.168.1.X
# =========================================================
# 1. Định nghĩa interface nhận sóng từ mạng gốc
WAN_IF="apclii0"

# 2. THẢ: Cho phép Newifi kết nối tới Router gốc (192.168.1.1) để lấy Internet
iptables -A INPUT -i $WAN_IF -s 192.168.1.1 -j ACCEPT

# 3. KHÓA INPUT: Chặn đứng tất cả các thiết bị khác thuộc dải 192.168.1.x mò vào bản thân con Newifi
iptables -A INPUT -i $WAN_IF -s 192.168.1.0/24 -j DROP

# 4. KHÓA FORWARD: Chặn tuyệt đối dải 192.168.1.x chọc sâu vào dải nội bộ 192.168.123.x của bạn
iptables -A FORWARD -i $WAN_IF -s 192.168.1.0/24 -d 192.168.123.0/24 -j DROP

logger -t "【BẢO MẬT WAN】" "Đã kích hoạt bức tường lửa cô lập dải mạng 192.168.1.x thành công!"

=========================================================
# LUỒNG CAO CẤP V17: HOÀN THIỆN ĐỒNG BỘ CACHE 8192 & BLOCK ADS
# =========================================================
(
    logger -t "【MOD HỆ THỐNG】" "Kích hoạt luồng tối ưu bộ nhớ & chặn quảng cáo V17..."

    # 1. Chờ hệ thống ổn định hoàn toàn
    sleep 15

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
) &

# 1. Khai báo thông số
WAN_IF=$(nvram get wan0_ifname) # Tự động lấy tên cổng WAN (thường là eth3)
DOWNLINK=220000                 # Tốc độ Download (kbit) - Đang set 180 Mbps
UPLINK=160000                   # Tốc độ Upload (kbit) - Đang set 180 Mbps

# 2. Xóa các lề luật cũ (nếu có) để tránh xung đột
tc qdisc del dev $WAN_IF root 2>/dev/null
tc qdisc del dev $WAN_IF ingress 2>/dev/null
tc qdisc del dev ifb0 root 2>/dev/null
tc qdisc del dev ifb0 ingress 2>/dev/null

# 3. Kích hoạt card mạng ảo IFB cho chiều Download
modprobe ifb numifbs=1
ip link set dev ifb0 up

# ==========================================
# 4. CẤU HÌNH UPLOAD (Dữ liệu đi ra từ WAN)
# ==========================================
# Tạo luật giới hạn băng thông bằng HTB
tc qdisc add dev $WAN_IF root handle 1: htb default 10
tc class add dev $WAN_IF parent 1: classid 1:1 htb rate ${UPLINK}kbit
tc class add dev $WAN_IF parent 1:1 classid 1:10 htb rate ${UPLINK}kbit ceil ${UPLINK}kbit
# Áp dụng thuật toán fq_codel để sắp xếp gói tin
tc qdisc add dev $WAN_IF parent 1:10 handle 10: fq_codel limit 1000 target 5ms interval 100ms

# ==========================================
# 5. CẤU HÌNH DOWNLOAD (Dữ liệu đi vào WAN -> ép qua IFB0)
# ==========================================
# Bắt gói tin đi vào WAN và ném sang IFB0
tc qdisc add dev $WAN_IF handle ffff: ingress
tc filter add dev $WAN_IF parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ifb0

# Tạo luật giới hạn băng thông HTB trên IFB0
tc qdisc add dev ifb0 root handle 1: htb default 10
tc class add dev ifb0 parent 1: classid 1:1 htb rate ${DOWNLINK}kbit
tc class add dev ifb0 parent 1:1 classid 1:10 htb rate ${DOWNLINK}kbit ceil ${DOWNLINK}kbit
# Áp dụng thuật toán fq_codel
tc qdisc add dev ifb0 parent 1:10 handle 10: fq_codel limit 1000 target 5ms interval 100ms
