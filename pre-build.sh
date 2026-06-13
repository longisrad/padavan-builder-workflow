#!/bin/bash

# Di chuyển vào thư mục trunk
cd padavan-ng/trunk

# Lệnh khởi tạo chính xác theo Product ID từ file 2068.png
fakeroot ./build_firmware_modify NEWIFI-D2

# Sau đó mới copy file config của bạn
cp -f ../../build.config .config

# Cập nhật cấu hình
make oldconfig
