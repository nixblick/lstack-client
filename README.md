# LSTack OS – Client (PoC)

## Ziel
Startfähiger Qt/QML-Client als UI-Stub. DB/LDAP/Karte folgen.

## Build (lokal)
```bash
sudo dnf/apt install -y cmake g++ qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel
cmake -B build -S .
cmake --build build -j
./build/lstack-client
