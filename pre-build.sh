#!/bin/bash
SRC="padavan-ng/trunk"

# Đảm bảo các thư mục tồn tại trước khi copy
mkdir -p "$SRC/user/scripts"
mkdir -p "$SRC/user/dnsmasq"
mkdir -p "$SRC/user/init"

# Kiểm tra file nguồn trước khi copy
if [ -f "my_init.sh" ]; then
    cp my_init.sh "$SRC/user/scripts/custom_init.sh"
    chmod +x "$SRC/user/scripts/custom_init.sh"
else
    echo "Lỗi: Không tìm thấy file my_init.sh trong repo!"
    exit 1
fi

# Ghi nội dung cấu hình dnsmasq
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
} >> "$SRC/user/dnsmasq/dnsmasq.conf"

# Đăng ký script khởi động
echo 'sh /etc/storage/custom_init.sh &' > "$SRC/user/init/S99_custom_init"
chmod +x "$SRC/user/init/S99_custom_init"
