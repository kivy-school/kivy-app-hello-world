import argparse
import os
import subprocess
import sys
import tomllib
from pathlib import Path


def load_config() -> dict:
    """Read pyproject.toml and extract app launcher config."""
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print("Error: pyproject.toml not found. Run this from the project root.", file=sys.stderr)
        sys.exit(1)

    with open(pyproject_path, "rb") as f:
        data = tomllib.load(f)

    psproject = data.get("tool", {}).get("psproject", {})
    app_name = psproject.get("app_name")
    if not app_name:
        print("Error: [tool.psproject] app_name not set in pyproject.toml", file=sys.stderr)
        sys.exit(1)

    bundle_id = f"org.pyswift.{app_name}"

    return {
        "app_name": app_name,
        "bundle_id": bundle_id,
        "xcode_proj": f"project_dist/xcode/{app_name}.xcodeproj",
        "xcode_build_dir": "project_dist/xcode/build",
        "gradle_dir": "project_dist/gradle",
    }


def run(cmd: list[str], check: bool = True, **kwargs) -> subprocess.CompletedProcess:
    print(f"+ {' '.join(cmd)}")
    return subprocess.run(cmd, check=check, **kwargs)


def build(cfg: dict, destination: str, config: str) -> None:
    run([
        "xcodebuild",
        "-project", cfg["xcode_proj"],
        "-scheme", cfg["app_name"],
        "-destination", destination,
        "-configuration", config,
        "-derivedDataPath", cfg["xcode_build_dir"],
        "-allowProvisioningUpdates",
        "build",
    ])


def run_ios(cfg: dict, uuid: str, config: str) -> None:
    build(cfg, f"platform=iOS,id={uuid}", config)
    app_path = f"{cfg['xcode_build_dir']}/Build/Products/{config}-iphoneos/{cfg['app_name']}.app"

    run(["xcrun", "devicectl", "device", "install", "app", "--device", uuid, app_path])
    run(["xcrun", "devicectl", "device", "process", "launch", "--device", uuid, cfg["bundle_id"], "--console"])


def run_sim(cfg: dict, uuid: str, config: str) -> None:
    build(cfg, f"platform=iOS Simulator,id={uuid}", config)
    app_path = f"{cfg['xcode_build_dir']}/Build/Products/{config}-iphonesimulator/{cfg['app_name']}.app"

    # Boot simulator (ignore if already booted)
    run(["xcrun", "simctl", "boot", uuid], check=False)
    # Open the Simulator app window
    run(["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", uuid])

    run(["xcrun", "simctl", "install", uuid, app_path])
    run(["xcrun", "simctl", "launch", "--console", uuid, cfg["bundle_id"]])


def run_macos(cfg: dict, config: str) -> None:
    build(cfg, "platform=macOS", config)
    app_path = f"{cfg['xcode_build_dir']}/Build/Products/{config}/{cfg['app_name']}.app"
    run(["open", "-W", app_path])


def run_android(cfg: dict, device: str | None, config: str) -> None:
    gradlew = os.path.join(cfg["gradle_dir"], "gradlew")
    gradle_task = "installRelease" if config == "Release" else "installDebug"

    # Build & install APK via Gradle
    run([gradlew, gradle_task])

    # Launch via adb
    adb = ["adb"]
    if device:
        adb += ["-s", device]

    activity = f"{cfg['bundle_id']}/{cfg['bundle_id']}.MainActivity"
    run(adb + ["shell", "am", "start", "-n", activity])

    # Stream logcat filtered to the app
    print("\n--- Streaming logcat (Ctrl+C to stop) ---\n")
    try:
        run(adb + ["logcat", "-v", "color", "--pid", _get_pid(adb, cfg["bundle_id"])])
    except KeyboardInterrupt:
        print("\nStopped.")


def _get_pid(adb: list[str], bundle_id: str) -> str:
    """Get the PID of the running app."""
    result = subprocess.run(
        adb + ["shell", "pidof", bundle_id],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


def main() -> None:
    cfg = load_config()

    parser = argparse.ArgumentParser(
        description=f"Build, install & run {cfg['app_name']}",
    )
    parser.add_argument(
        "platform",
        choices=["ios", "sim", "macos", "android"],
        help="Target platform: ios (physical iPhone), sim (iOS Simulator), macos, android",
    )
    parser.add_argument(
        "uuid",
        nargs="?",
        default=None,
        help="Device/simulator UUID (required for ios/sim, optional for android - adb serial)",
    )
    parser.add_argument(
        "--release",
        action="store_true",
        default=False,
        help="Build in Release mode (default: Debug)",
    )
    args = parser.parse_args()

    if args.platform in ("ios", "sim") and not args.uuid:
        parser.error(f"UUID is required for platform '{args.platform}'")

    config = "Release" if args.release else "Debug"

    match args.platform:
        case "ios":
            run_ios(cfg, args.uuid, config)
        case "sim":
            run_sim(cfg, args.uuid, config)
        case "macos":
            run_macos(cfg, config)
        case "android":
            run_android(cfg, args.uuid, config)
