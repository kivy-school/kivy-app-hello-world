# Running the Xcode Project on an iPhone Device (Terminal)

All commands assume you're in the **workspace root** directory.  
The Xcode project is always at: `project_dist/xcode/MyNewKivyApp.xcodeproj`

---

## Prerequisites

- **Xcode** installed (with command-line tools: `xcode-select --install`)
- **Apple Developer account** signed into Xcode (needed for signing — do this once via Xcode preferences)
- **iPhone** connected via USB (or paired wirelessly), unlocked and trusted
- **`uv`** on your `PATH` (the build phase uses `uv python find 3.13.8`)

---

## 1. Find Your Device & UDID

```bash
# List all connected devices (shows name, platform, and UDID)
xcrun xctrace list devices
```

Example output:
```
== Devices ==
John's iPhone (17.5)              00008110-XXXXXXXXXXXX
```

The hex string at the end is the **UDID**.

You can also get just the UDID of a connected device with:

```bash
# Via system_profiler (works without Xcode running)
system_profiler SPUSBDataType 2>/dev/null | grep -A2 "iPhone" | grep "Serial Number" | awk '{print $NF}'

# Or via devicectl (more reliable, shows all paired devices)
xcrun devicectl list devices
```

Note the device **name** (e.g. `John's iPhone`) or **UDID** from the output.

---

## 2. Build for iPhone Device

**By device name:**

```bash
xcodebuild \
  -project project_dist/xcode/MyNewKivyApp.xcodeproj \
  -scheme MyNewKivyApp \
  -destination 'platform=iOS,name=lexincs\ iPad\ Pro' \
  -configuration Debug \
  -allowProvisioningUpdates \
  build
```

**By device UDID:**

```bash
xcodebuild \
  -project project_dist/xcode/MyNewKivyApp.xcodeproj \
  -scheme MyNewKivyApp \
  -destination 'platform=iOS,id=00008103-000624383C31001E' \
  -configuration Debug \
  -allowProvisioningUpdates \
  build
```

> The `-allowProvisioningUpdates` flag lets `xcodebuild` automatically manage signing profiles.

The built app will be at:  
`project_dist/xcode/build/Build/Products/Debug-iphoneos/MyNewKivyApp.app`  
(or under the derived data path shown in the build output)

---

## 3. Install on Device

```bash
xcrun devicectl device install app \
  --device DEVICE_UDID \
  project_dist/xcode/build/Build/Products/Debug-iphoneos/MyNewKivyApp.app
```

> If the build output goes to DerivedData instead, find the `.app` with:
> ```bash
> find ~/Library/Developer/Xcode/DerivedData -name "MyNewKivyApp.app" -path "*/Debug-iphoneos/*" | head -1
> ```

---

## 4. Launch on Device

```bash
xcrun devicectl device process launch \
  --device DEVICE_UDID \
  org.pyswift.MyNewKivyApp
```

---

## Build + Install + Launch (One-Liner)

You can chain the build with a custom `SYMROOT` so the output path is predictable:

```bash
PROJ=project_dist/xcode/MyNewKivyApp.xcodeproj && \
BUILD_DIR=project_dist/xcode/build && \
DEVICE_UDID="YOUR_DEVICE_UDID" && \
xcodebuild \
  -project "$PROJ" \
  -scheme MyNewKivyApp \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -configuration Debug \
  -allowProvisioningUpdates \
  SYMROOT="$BUILD_DIR" \
  build && \
xcrun devicectl device install app \
  --device "$DEVICE_UDID" \
  "$BUILD_DIR/Debug-iphoneos/MyNewKivyApp.app" && \
xcrun devicectl device process launch \
  --device "$DEVICE_UDID" \
  org.pyswift.MyNewKivyApp
```

---

## Useful Commands

```bash
# List connected devices
xcrun xctrace list devices

# Check available schemes in the project
xcodebuild -project project_dist/xcode/MyNewKivyApp.xcodeproj -list

# Clean build artifacts
xcodebuild \
  -project project_dist/xcode/MyNewKivyApp.xcodeproj \
  -scheme MyNewKivyApp \
  clean

# Resolve Swift Package dependencies manually
xcodebuild \
  -project project_dist/xcode/MyNewKivyApp.xcodeproj \
  -resolvePackageDependencies

# View device logs (useful for debugging)
xcrun devicectl device info log show --device DEVICE_UDID
```

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| **Device not listed** | Ensure iPhone is unlocked, trusted, and connected. Run `xcrun xctrace list devices`. |
| **Signing error** | Make sure you've signed into a dev account in Xcode at least once. Use `-allowProvisioningUpdates`. |
| **"Untrusted Developer" on iPhone** | On device: Settings → General → VPN & Device Management → Trust your certificate. |
| **`uv` not found during build** | Ensure `uv` is installed and on `PATH`. The build phase runs `uv python find 3.13.8`. |
| **Package resolution fails** | Run `xcodebuild -resolvePackageDependencies` on the project first. |

---

## Project Reference

| Property | Value |
|----------|-------|
| **Project Path** | `project_dist/xcode/MyNewKivyApp.xcodeproj` |
| **Target** | `MyNewKivyApp` |
| **Bundle ID** | `org.pyswift.MyNewKivyApp` |
| **Supported Platforms** | `iphoneos`, `iphonesimulator`, `macosx` |
| **Dependencies** | CPython (≥ 313.0.0), PySwiftKit (≥ 313.0.0) |
