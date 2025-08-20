#!/usr/bin/env bash
# packaging/make-appimage.sh - Mit GLIBC Check
set -euo pipefail

# Config
APP_NAME="LSTack OS Client"
BIN_NAME="lstack-client"
APP_ID="io.lstack.client"
BUILD_TYPE="${BUILD_TYPE:-Release}"
SRC_DIR="${SRC_DIR:-$(pwd)}"
BUILD_DIR="${BUILD_DIR:-${SRC_DIR}/build}"
DIST_DIR="${DIST_DIR:-${SRC_DIR}/dist}"
APPDIR="${APPDIR:-${BUILD_DIR}/AppDir}"
ICON_FILE="${ICON_FILE:-${SRC_DIR}/resources/icons/lstack-client.png}"

# Tools
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"

log() { printf "\033[1;34m[make-appimage]\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m[make-appimage]\033[0m %s\n" "$*" >&2; exit 1; }

# GLIBC Version checken
check_glibc() {
  local glibc_version
  if command -v ldd >/dev/null 2>&1; then
    glibc_version=$(ldd --version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
    log "Build System GLIBC: $glibc_version"
    
    # Warnung bei neuen Versionen
    if awk -v ver="$glibc_version" 'BEGIN{exit(ver>=2.35)}'; then
      log "GLIBC $glibc_version ist kompatibel mit älteren Systemen"
    else
      log "WARNUNG: GLIBC $glibc_version - AppImage läuft nur auf neueren Systemen"
    fi
  fi
}

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

check_glibc
mkdir -p "$BUILD_DIR" "$DIST_DIR"
VERSION="${VERSION:-$(version_from_git)}"
ARCH="$(uname -m)"
OS_SUFFIX="${OS_SUFFIX:-}"

# Build
log "Building …"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$BUILD_DIR" -j"$(nproc)"

BIN_PATH="${BUILD_DIR}/${BIN_NAME}"
[[ -x "$BIN_PATH" ]] || fail "Binary not found at ${BIN_PATH}"

# AppDir
log "Creating AppDir …"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications"

install -m 0755 "$BIN_PATH" "$APPDIR/usr/bin/${BIN_NAME}"

# Desktop file
cat > "$APPDIR/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Exec=${BIN_NAME}
Icon=${APP_ID}
Type=Application
Categories=Utility;
Terminal=false
EOF

# Icon (optional)
if [[ -f "$ICON_FILE" ]]; then
  mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
  install -m 0644 "$ICON_FILE" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
fi

# linuxdeploy
TOOLS_DIR="${BUILD_DIR}/_tools"
mkdir -p "$TOOLS_DIR"
LINUXDEPLOY="${TOOLS_DIR}/linuxdeploy.AppImage"
LINUXDEPLOY_QT="${TOOLS_DIR}/linuxdeploy-plugin-qt.AppImage"

dl_tool "$LINUXDEPLOY_URL" "$LINUXDEPLOY"
dl_tool "$LINUXDEPLOY_QT_URL" "$LINUXDEPLOY_QT"

export VERSION
export APPIMAGE_EXTRACT_AND_RUN=1
export QML_SOURCES_PATHS="${SRC_DIR}/ui"

log "Creating AppImage …"
"$LINUXDEPLOY" --appdir "$APPDIR" \
  -e "$APPDIR/usr/bin/${BIN_NAME}" \
  -d "$APPDIR/${APP_ID}.desktop" \
  $([ -f "$ICON_FILE" ] && echo "-i $APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png") \
  --plugin qt \
  --output appimage

# Move result mit OS-Suffix
artifact="$(ls -1 *.AppImage 2>/dev/null | head -n1)"
[[ -f "$artifact" ]] || fail "No AppImage generated"
final="${DIST_DIR}/${BIN_NAME}-${VERSION}${OS_SUFFIX:+-$OS_SUFFIX}-${ARCH}.AppImage"
mv "$artifact" "$final"
chmod +x "$final"

log "AppImage ready: $final"