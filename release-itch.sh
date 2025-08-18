#!/bin/bash
mkdir release
cd release
curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
unzip butler.zip
chmod +x butler
./butler push ../export/abschlussquiz-linux-x86_64.bin thecheeseknife/abschlussquiz:linux-x86_64 --userversion-file ../version.txt
./butler push ../export/abschlussquiz-linux-x86_32.bin thecheeseknife/abschlussquiz:linux-x86_32 --userversion-file ../version.txt
./butler push ../export/abschlussquiz-linux-arm64.bin thecheeseknife/abschlussquiz:linux-arm64 --userversion-file ../version.txt
./butler push ../export/abschlussquiz-windows-x86_64-setup.msi thecheeseknife/abschlussquiz:windows-x86_64-setup --userversion-file ../version.txt
./butler push ../export/abschlussquiz-windows-x86_64-portable.exe thecheeseknife/abschlussquiz:windows-x86_64-portable --userversion-file ../version.txt
./butler push ../export/abschlussquiz-windows-x86_32-setup.msi thecheeseknife/abschlussquiz:windows-x86_32-setup --userversion-file ../version.txt
./butler push ../export/abschlussquiz-windows-x86_32-portable.exe thecheeseknife/abschlussquiz:windows-x86_32-portable --userversion-file ../version.txt
./butler push ../export/abschlussquiz-windows-arm64-portable.exe thecheeseknife/abschlussquiz:windows-arm64-portable --userversion-file ../version.txt
./butler push ../export/abschlussquiz-android.apk thecheeseknife/abschlussquiz:android-armeabi-v7a-arm64-v8a --userversion-file ../version.txt
cd ..
rm -rf release/
