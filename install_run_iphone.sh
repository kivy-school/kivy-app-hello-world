
set -e

PLATFORM=$1
UUID=$2
BUILD_DIR=project_dist/xcode/build
BUNDLE_ID=org.pyswift.MyNewKivyApp
PROJ=project_dist/xcode/MyNewKivyApp.xcodeproj

usage() {
  echo "Usage: $0 <platform> [device-uuid]"
  echo ""
  echo "Platforms:"
  echo "  ios    Build, install & run on a physical iPhone (requires UUID)"
  echo "  sim    Build, install & run on iOS Simulator (requires simulator UUID)"
  echo "  macos  Build & run on macOS (no UUID needed)"
  echo ""
  echo "Examples:"
  echo "  $0 ios 00008103-000624383C31001E"
  echo "  $0 sim 5FE09478-1964-4F02-8C5C-E152A261D93A"
  echo "  $0 macos"
  exit 1
}

if [ -z "$PLATFORM" ]; then
  usage
fi

case "$PLATFORM" in
  ios)
    [ -z "$UUID" ] && echo "Error: UUID required for ios" && exit 1

    xcodebuild \
      -project "$PROJ" \
      -scheme MyNewKivyApp \
      -destination "platform=iOS,id=$UUID" \
      -configuration Debug \
      -derivedDataPath "$BUILD_DIR" \
      -allowProvisioningUpdates \
      build

    APP_PATH="$BUILD_DIR/Build/Products/Debug-iphoneos/MyNewKivyApp.app"

    xcrun devicectl device install app \
      --device "$UUID" \
      "$APP_PATH"

    xcrun devicectl device process launch \
      --device "$UUID" \
      "$BUNDLE_ID" \
      --console
    ;;

  sim)
    [ -z "$UUID" ] && echo "Error: Simulator UUID required for sim" && exit 1

    xcodebuild \
      -project "$PROJ" \
      -scheme MyNewKivyApp \
      -destination "platform=iOS Simulator,id=$UUID" \
      -configuration Debug \
      -derivedDataPath "$BUILD_DIR" \
      -allowProvisioningUpdates \
      build

    APP_PATH="$BUILD_DIR/Build/Products/Debug-iphonesimulator/MyNewKivyApp.app"

    # Boot the simulator if not already booted
    xcrun simctl boot "$UUID" 2>/dev/null || true
    # Open the Simulator app window
    open -a Simulator --args -CurrentDeviceUDID "$UUID"

    xcrun simctl install "$UUID" "$APP_PATH"
    xcrun simctl launch --console "$UUID" "$BUNDLE_ID"
    ;;

  macos)
    xcodebuild \
      -project "$PROJ" \
      -scheme MyNewKivyApp \
      -destination "platform=macOS" \
      -configuration Debug \
      -derivedDataPath "$BUILD_DIR" \
      -allowProvisioningUpdates \
      build

    APP_PATH="$BUILD_DIR/Build/Products/Debug/MyNewKivyApp.app"

    open -W "$APP_PATH"
    ;;

  *)
    echo "Error: Unknown platform '$PLATFORM'"
    usage
    ;;
esac