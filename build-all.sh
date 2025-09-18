godotengine --headless --export-release "Linux x86_64" "export/abschlussquiz-linux-x86_64.bin"
godotengine --headless --export-release "Linux x86_32" "export/abschlussquiz-linux-x86_32.bin"
godotengine --headless --export-release "Linux arm64" "export/abschlussquiz-linux-arm64.bin"
godotengine --headless --export-release "Windows Desktop x86_64" "export/abschlussquiz-windows-x86_64-portable.exe"
godotengine --headless --export-release "Windows Desktop x86_32" "export/abschlussquiz-windows-x86_32-portable.exe"
godotengine --headless --export-release "Windows Desktop arm64" "export/abschlussquiz-windows-arm64-portable.exe"
godotengine --headless --export-release "Android armeabi-v7a-arm64-v8a" "export/abschlussquiz-android.apk"

cd wix/x86_64
./build-installer.sh
cp bin/Release/abschlussquiz-windows-x86_64-setup.msi ../../export/
cd ../x86_32
./build-installer.sh
cp bin/Release/abschlussquiz-windows-x86_32-setup.msi ../../export/
cd ../..
