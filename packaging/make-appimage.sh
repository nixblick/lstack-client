# packaging/make-appimage.sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
DIST_DIR="$ROOT/dist"
APPDIR="$ROOT/AppDir"
CACHE_DIR="$ROOT/.cache/linuxdeploy"

APP_ID="${APP_ID:-lstack-client}"
APP_NAME="${APP_NAME:-LSTack Client}"
BIN_NAME="${BIN_NAME:-lstack-client}"
OS_SUFFIX="${OS_SUFFIX:-generic}"

mkdir -p "$DIST_DIR" "$CACHE_DIR"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# locate built binary
if [[ -z "${BIN_PATH:-}" ]]; then
  if [[ -x "$BUILD_DIR/$BIN_NAME" ]]; then
    BIN_PATH="$BUILD_DIR/$BIN_NAME"
  else
    BIN_PATH="$(find "$BUILD_DIR" -maxdepth 3 -type f -perm -111 -name "$BIN_NAME" | head -n1 || true)"
  fi
fi
[[ -n "${BIN_PATH:-}" ]] || { echo "ERROR: binary '$BIN_NAME' not found in $BUILD_DIR"; exit 1; }
install -m0755 "$BIN_PATH" "$APPDIR/usr/bin/$BIN_NAME"

# desktop file
DESKTOP_SRC="$ROOT/packaging/${APP_ID}.desktop"
if [[ ! -f "$DESKTOP_SRC" ]]; then
  cat >"$DESKTOP_SRC" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=$BIN_NAME
Icon=$APP_ID
Categories=Utility;
Terminal=false
EOF
fi
cp -f "$DESKTOP_SRC" "$APPDIR/usr/share/applications/${APP_ID}.desktop"

# icon (optional)
ICON_PNG="$ROOT/resources/icons/${APP_ID}.png"
if [[ -f "$ICON_PNG" ]]; then
  install -Dm0644 "$ICON_PNG" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
fi

# get linuxdeploy + qt plugin
LD="$CACHE_DIR/linuxdeploy"
LD_QT="$CACHE_DIR/linuxdeploy-plugin-qt"
export PATH="$CACHE_DIR:$PATH"

if [[ ! -x "$LD" ]]; then
  curl -sSLf -o "$LD" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  chmod +x "$LD"
fi
if [[ ! -x "$LD_QT" ]]; then
  curl -sSLf -o "$LD_QT" https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
  chmod +x "$LD_QT"
fi

# run without FUSE everywhere
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"

# bundle OpenSSL if present on the builder
OPENSSL_ARGS=()
for cand in \
  /usr/lib64/libssl.so.3 /usr/lib64/libcrypto.so.3 \
  /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/libcrypto.so.3 \
  /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1
do
  [[ -f "$cand" ]] && OPENSSL_ARGS+=(-l "$cand")
done

# build AppImage
"$LD" --appdir "$APPDIR" \
  -e "$APPDIR/usr/bin/$BIN_NAME" \
  -d "$APPDIR/usr/share/applications/${APP_ID}.desktop" \
  -i "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" \
  "${OPENSSL_ARGS[@]}" \
  --plugin qt \
  --output appimage

# move output to dist with clear name
OUT="$(ls -1 ./*.AppImage | head -n1)"
TARGET="${DIST_DIR}/${APP_ID}-${OS_SUFFIX}.AppImage"
mv -f "$OUT" "$TARGET"
echo "Created: $TARGET"
