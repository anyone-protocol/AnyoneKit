#!/bin/sh

VERSION=$1

cd AnyoneKit/Assets

# Test if file is older then 1 week.
OLD="$(find geoip -mmin +10080 2>/dev/null)"

# Only download, if files are not existing or older than 1 week.
if [ ! -f geoip -o ! -z "$OLD" ]; then
    wget https://raw.githubusercontent.com/anyone-protocol/ator-protocol/refs/heads/main/src/config/geoip
    wget https://raw.githubusercontent.com/anyone-protocol/ator-protocol/refs/heads/main/src/config/geoip6
fi

cd ../..

# Test if folder is older then 1 week.
OLD="$(find anon.xcframework -mmin +10080 2>/dev/null)"

if [ ! -d anon.xcframework -o ! -z "$OLD" ]; then
    wget "https://github.com/anyone-protocol/AnyoneKit/releases/download/$VERSION/anon.xcframework.zip"
    unzip anon.xcframework.zip
    rm anon.xcframework.zip
fi
