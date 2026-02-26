ARCH=$1

OUTPUT_DIR=$2

KIVY_PATH="kivy"

git clone https://github.com/kivy/kivy.git

cp -f fix_macos_frameworks.sh "$KIVY_PATH/tools/fix_macos_frameworks.sh"

cd $KIVY_PATH

#export CIBW_ENVIRONMENT_ANDROID="ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/27.3.13750724"



chmod +x ./tools/build_macos_dependencies.sh
chmod +x ./tools/fix_macos_frameworks.sh
chmod +x ./tools/cibuildwheel-before-all-ios.sh

export CIBW_BUILD=cp313-*

export CIBW_ENVIRONMENT_IOS=IOSSDKROOT="$(xcrun --show-sdk-path --sdk iphoneos)"
export CIBW_BEFORE_ALL_IOS="./tools/cibuildwheel-before-all-ios.sh"

uv run cibuildwheel --platform ios --archs arm64_iphoneos --output-dir "$OUTPUT_DIR"

export CIBW_ENVIRONMENT_IOS=IOSSDKROOT="$(xcrun --show-sdk-path --sdk iphonesimulator)"
uv run cibuildwheel --platform ios --archs x86_64_iphonesimulator --output-dir "$OUTPUT_DIR"

export CIBW_BEFORE_ALL_MACOS="./tools/build_macos_dependencies.sh && ./tools/fix_macos_frameworks.sh"

export CIBW_ENVIRONMENT_MACOS="SDKROOT='$(xcrun --show-sdk-path)' KIVY_DEPS_ROOT='./kivy-dependencies' REPAIR_LIBRARY_PATH='./kivy-dependencies/dist/Frameworks' MACOSX_DEPLOYMENT_TARGET='10.15' CFLAGS='-isysroot $(xcrun --show-sdk-path)' CPPFLAGS='-isysroot $(xcrun --show-sdk-path)'"

uv run cibuildwheel --platform macos --archs $ARCH --output-dir "$OUTPUT_DIR"
#uv run cibuildwheel --only cp313-macosx_arm64 --output-dir "$OUTPUT_DIR"

