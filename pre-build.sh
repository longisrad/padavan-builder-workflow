#!/bin/bash
SRC="padavan-ng/trunk"

# 1. Copy script khởi động chính (my_init.sh phải nằm trong thư mục gốc của Repo)
mkdir -p "$SRC/user/scripts"
cp my_init.sh "$SRC/user/scripts/custom_init.sh"
chmod +x "$SRC/user/scripts/custom_init.sh"

# 2. Tạo file cấu hình DNS tích hợp
# Chúng ta ghi vào dnsmasq.conf để nạp file hosts và chặn các tên miền theo dõi
mkdir -p "$SRC/user/dnsmasq"
{
    echo "addn-hosts=/etc/storage/dnsmasq/abpvn.hosts"
    echo "address=/update.miui.com/0.0.0.0"
    echo "address=/ota.miui.com/0.0.0.0"
    echo "address=/io.mi.com/0.0.0.0"
    echo "address=/api.io.mi.com/0.0.0.0"
    echo "address=/register.xiaoqiang.miwifi.com/0.0.0.0"
    echo "address=/update.xiaoqiang.miwifi.com/0.0.0.0"
    echo "address=/andlink.cmri.cn/0.0.0.0"
    echo "address=/config.andlink.cmri.cn/0.0.0.0"
    echo "address=/dm.andlink.cmri.cn/0.0.0.0"
    echo "address=/iot.andlink.cmri.cn/0.0.0.0"
    echo "address=/upgrade.andlink.cmri.cn/0.0.0.0"
    echo "address=/andlink.10086.cn/0.0.0.0"
    echo "address=/api.miwifi.com/0.0.0.0"
    echo "address=/data.mistat.xiaomi.com/0.0.0.0"
} >> "$SRC/user/dnsmas
