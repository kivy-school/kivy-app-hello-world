#!/bin/bash
# Fix @rpath references in SDL3 satellite frameworks for delocate compatibility
# delocate-wheel cannot resolve @rpath references, so we change them to @loader_path
# This script should be run after build_macos_dependencies.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORKS_DIR="${KIVY_DEPS_ROOT:-$SCRIPT_DIR/../kivy-dependencies}/dist/Frameworks"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Error: Frameworks directory not found: $FRAMEWORKS_DIR"
    exit 1
fi

echo "Fixing framework install names in: $FRAMEWORKS_DIR"

# SDL3_ttf depends on SDL3 and png
SDL3_TTF="$FRAMEWORKS_DIR/SDL3_ttf.framework/Versions/A/SDL3_ttf"
if [ -f "$SDL3_TTF" ]; then
    echo "Fixing SDL3_ttf..."
    install_name_tool -change \
        "@rpath/SDL3.framework/Versions/A/SDL3" \
        "@loader_path/../../../SDL3.framework/Versions/A/SDL3" \
        "$SDL3_TTF"
    # Find and fix png reference (version may vary)
    PNG_REF=$(otool -L "$SDL3_TTF" | grep "@rpath/png.framework" | awk '{print $1}' || true)
    if [ -n "$PNG_REF" ]; then
        PNG_NEW=$(echo "$PNG_REF" | sed 's|@rpath/|@loader_path/../../../|')
        install_name_tool -change "$PNG_REF" "$PNG_NEW" "$SDL3_TTF"
    fi
    codesign --force --sign - "$SDL3_TTF"
fi

# SDL3_image depends on SDL3
SDL3_IMAGE="$FRAMEWORKS_DIR/SDL3_image.framework/Versions/A/SDL3_image"
if [ -f "$SDL3_IMAGE" ]; then
    echo "Fixing SDL3_image..."
    install_name_tool -change \
        "@rpath/SDL3.framework/Versions/A/SDL3" \
        "@loader_path/../../../SDL3.framework/Versions/A/SDL3" \
        "$SDL3_IMAGE"
    codesign --force --sign - "$SDL3_IMAGE"
fi

# SDL3_mixer depends on SDL3
SDL3_MIXER="$FRAMEWORKS_DIR/SDL3_mixer.framework/Versions/A/SDL3_mixer"
if [ -f "$SDL3_MIXER" ]; then
    echo "Fixing SDL3_mixer..."
    install_name_tool -change \
        "@rpath/SDL3.framework/Versions/A/SDL3" \
        "@loader_path/../../../SDL3.framework/Versions/A/SDL3" \
        "$SDL3_MIXER"
    codesign --force --sign - "$SDL3_MIXER"
fi

echo "Framework install names fixed successfully"
