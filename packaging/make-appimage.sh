#!/usr/bin/env bash
# packaging/make-appimage.sh
# Build Qt/C++ client and package as AppImage (portable).
set -euo pipefail

# ---------- Config (edit if needed) ----------
APP_NAME="LSTack OS Client"
BIN_NAME="lstack-client"
APP_ID="io.lstack.client"
CATEGORY="Utility;System;"
LICENSE="Apache-2.0"
BUILD_TYPE="${BUILD_TYPE:-Release}"
SRC_DIR="${SRC_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BUILD_DIR="${BUILD_DIR:-${SRC_DIR}/build}"
DIST_DIR="${DIST_DIR:-${SRC_DIR}/dist}"
APPDIR="${APPDIR:-${BUILD_DIR}/AppDir}"
ICON_FILE="${ICON_FILE:-${SRC_DIR}/resources/icons/lstack-client.png}"
QML_DIRS="${QML_DIRS:-${SRC_DIR}/ui:${SRC_DIR}/qml:${SRC_DIR}/resources/qml}"
# Optional extra Qt plugins (space-separated), e.g.: "positioning location"
QT_PLUGINS="${QT_PLUGINS:-positioning location}"

# Tools (download if missing)
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"

# ---------- Helpers ----------
log() { printf "\033[1;34m[make-appimage]\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m[make-appimage]\033[0m %s\n" "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || fail "Missing tool: $1"; }

dl_tool() {
  local url="$1" out="$2"
  if [[ ! -x "$out" ]]; then
    log "Downloading $(basename "$out") …"
    curl -fsSL "$url" -o "$out" || wget -q "$url" -O "$out"
    chmod +x "$out"
  fi
}

version_from_git() {
  if git -C "$SRC_DIR" describe --tags --dirty --always >/dev/null 2>&1; then
    git -C "$SRC_DIR" describe --tags --dirty --always | sed 's/^v//'
  else
    date +%Y.%m.%d
  fi
}

arch_detect() {
  uname -m | sed 's/x86_64/x86_64/; s/aarch64/arm64/; s/armv7l/armhf/;'
}

# ---------- Preflight ----------
need cmake
need make
need patchelf || true
need curl || need wget

mkdir -p "$BUILD_DIR" "$DIST_DIR"
VERSION="${VERSION:-$(version_from_git)}"
ARCH="${ARCH:-$(arch_detect)}"

# ---------- Build ----------
log "Configuring (CMake, ${BUILD_TYPE}) …"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
log "Building …"
cmake --build "$BUILD_DIR" -j"$(nproc)"

# KORRIGIERT: Binary liegt im build root, nicht in build/bin
BIN_PATH="${BUILD_DIR}/${BIN_NAME}"
[[ -x "$BIN_PATH" ]] || fail "Binary not found at ${BIN_PATH}"

# ---------- AppDir layout ----------
log "Preparing AppDir …"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

install -m 0755 "$BIN_PATH" "$APPDIR/usr/bin/${BIN_NAME}"

# desktop entry
cat > "$APPDIR/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Exec=${BIN_NAME}
Icon=${APP_ID}
Type=Application
Categories=${CATEGORY}
Terminal=false
EOF

# icon
if [[ -f "$ICON_FILE" ]]; then
  install -m 0644 "$ICON_FILE" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
else
  log "Icon not found (${ICON_FILE}), using placeholder."
  convert -size 256x256 xc:white -gravity center -pointsize 22 -annotate 0 "${APP_NAME}" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" 2>/dev/null || true
fi

# metainfo (optional)
mkdir -p "$APPDIR/usr/share/metainfo"
cat > "$APPDIR/usr/share/metainfo/${APP_ID}.appdata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>${APP_ID}.desktop</id>
  <name>${APP_NAME}</name>
  <summary>Leitstellen-Client</summary>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>${LICENSE}</project_license>
  <developer_name>LSTack OS</developer_name>
  <releases><release version="${VERSION}" /></releases>
</component>
EOF

# ---------- linuxdeploy (+ Qt plugin) ----------
TOOLS_DIR="${BUILD_DIR}/_tools"
mkdir -p "$TOOLS_DIR"
LINUXDEPLOY="${TOOLS_DIR}/linuxdeploy.AppImage"
LINUXDEPLOY_QT="${TOOLS_DIR}/linuxdeploy-plugin-qt.AppImage"

dl_tool "$LINUXDEPLOY_URL" "$LINUXDEPLOY"
dl_tool "$LINUXDEPLOY_QT_URL" "$LINUXDEPLOY_QT"

export VERSION
export QML_SOURCES_PATHS="$QML_DIRS"

# Build with Qt plugin and requested extra plugins
log "Bundling dependencies with linuxdeploy …"

# Workaround for FUSE-less environments
export APPIMAGE_EXTRACT_AND_RUN=1

"$LINUXDEPLOY" --appdir "$APPDIR" \
  -e "$APPDIR/usr/bin/${BIN_NAME}" \
  -d "$APPDIR/${APP_ID}.desktop" \
  -i "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" \
  --plugin qt \
  --output appimage

# ---------- Move artifact ----------
artifact="$(ls -1 *.AppImage | head -n1)"
[[ -f "$artifact" ]] || fail "AppImage not generated."
final="${DIST_DIR}/${BIN_NAME}-${VERSION}-${ARCH}.AppImage"
mv -f "$artifact" "$final"
chmod +x "$final"
log "AppImage ready: $final"

# ---------- Optional: zsync for delta updates ----------
if command -v zsyncmake >/dev/null 2>&1; then
  ( cd "$DIST_DIR" && zsyncmake "$(basename "$final")" ) || true
fi

log "Done."