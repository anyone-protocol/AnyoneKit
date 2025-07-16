#!/bin/sh

VERSION=$1

load() {
    curl --remote-name --progress-bar --location $1
}

cd AnyoneKit/Assets

# Test if file is older then 1 week.
OLD="$(find geoip -mmin +10080 2>/dev/null)"

# Only download, if files are not existing or older than 1 week.
if [ ! -f geoip -o ! -z "$OLD" ]; then
    load https://raw.githubusercontent.com/anyone-protocol/ator-protocol/refs/heads/main/src/config/geoip
    load https://raw.githubusercontent.com/anyone-protocol/ator-protocol/refs/heads/main/src/config/geoip6
fi

cd ../..

if [ ! -d anon.xcframework ]; then
    load "https://github.com/anyone-protocol/AnyoneKit/releases/download/$VERSION/anon.xcframework.zip"
    unzip anon.xcframework.zip
    rm anon.xcframework.zip
fi
