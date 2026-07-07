#!/bin/bash
# 一键编译 + 烧录
set -euo pipefail
echo "🔨 编译 + 烧录"

cd "$(dirname "$0")/../firmware"

echo "  [1/2] 编译固件..."
make clean
make -j6 all
echo "  ✅ 编译完成"

echo "  [2/2] 烧录到芯片..."
openocd -f openocd.cfg -c "program build/{{PROJECT_NAME}}.elf verify reset exit"
echo "  ✅ 烧录完成，设备已复位运行"
