WINEARCH="win32" WINEPREFIX="$HOME/.wine32" wine dotnet add package WiXToolset.UI.wixext

WINEARCH="win32" WINEPREFIX="$HOME/.wine32" wine dotnet build --configuration Release

if [ $? -ne 0 ]; then
    echo "First attempt failed. Retrying..."
    WINEARCH="win32" WINEPREFIX="$HOME/.wine32" wine dotnet build --configuration Release
fi
