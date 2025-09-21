#!/bin/bash

LATEST=$(curl -s https://raw.githubusercontent.com/naomisphere/macpaper/main/latest)
CURRENT="$1"

if [ "$LATEST" != "$CURRENT" ]; then
    C_TMPDIR="$2/.tmp"
    mkdir -p "$C_TMPDIR"
    
    LATEST_URL="https://github.com/naomisphere/macpaper/releases/download/$LATEST/macpaper.dmg"
    DMG_PATH="$C_TMPDIR/macpaper.dmg"
    
    curl -L -o "$DMG_PATH" "$LATEST_URL"

    if [ -d "/Volumes/macpaper" ]; then
        hdiutil detach /Volumes/macpaper -force
    fi
    
    hdiutil attach "$DMG_PATH"
    cp -rf "/Volumes/macpaper/macpaper.app" "/Applications/"
    hdiutil detach /Volumes/macpaper
    
    # clean up
    rm -rf "$C_TMPDIR"
    
    echo "update completed"
else
    echo "app is up to date"
fi

exit 0