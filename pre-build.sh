#!/bin/bash
# Copy file config của bạn vào trunk/.config
cp build.config padavan-ng/trunk/.config

# Nếu bạn muốn chắc chắn các thiết lập được nạp, hãy chạy lệnh này:
cd padavan-ng/trunk
make oldconfig
