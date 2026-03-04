#!/bin/bash

# 自动编译 mlx-swift-lm 为 .xcframework 的脚本
# 需要在 macOS 环境运行，且已安装 Xcode 命令行工具

set -e

REPO_URL="https://github.com/ml-explore/mlx-swift-lm.git"
TAG="2.30.6" # 锁定的稳定版本，对应 mlx-swift 0.30.6
BUILD_DIR="build_xcframework"
OUTPUT_DIR="Frameworks"
PROJECT_NAME="MLXLLM" # 我们以此为主入口进行编译

# 1. 克隆/更新代码
if [ ! -d "$BUILD_DIR" ]; then
    echo "Cloning mlx-swift-lm (Tag: $TAG)..."
    git clone --branch $TAG --depth 1 --recursive $REPO_URL $BUILD_DIR
else
    echo "Updating mlx-swift-lm to Tag: $TAG..."
    cd $BUILD_DIR
    git fetch --tags
    git checkout $TAG
    git submodule update --init --recursive
    cd ..
fi

cd $BUILD_DIR

# 2. 编译 macOS 架构
echo "Building for macOS..."
xcodebuild archive \
    -workspace . \
    -scheme $PROJECT_NAME \
    -destination "generic/platform=macOS" \
    -archivePath "archives/macOS.xcarchive" \
    SKIP_INSTALL=NO \
    OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

# 3. 编译 iOS 架构 (如果需要)
echo "Building for iOS..."
xcodebuild archive \
    -workspace . \
    -scheme $PROJECT_NAME \
    -destination "generic/platform=iOS" \
    -archivePath "archives/iOS.xcarchive" \
    SKIP_INSTALL=NO \
    OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

# 4. 创建 xcframework
echo "Creating xcframework..."
rm -rf "../$OUTPUT_DIR"
mkdir -p "../$OUTPUT_DIR"

# 注意：这里需要根据具体的 Target 名称进行调整，mlx-swift-lm 包含多个子模块
# 示例：
xcodebuild -create-xcframework \
    -archive archives/macOS.xcarchive -framework $PROJECT_NAME.framework \
    -archive archives/iOS.xcarchive -framework $PROJECT_NAME.framework \
    -output "../$OUTPUT_DIR/$PROJECT_NAME.xcframework"

echo "Done! XCFramework is generated in $OUTPUT_DIR"
