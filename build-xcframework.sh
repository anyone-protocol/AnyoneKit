#!/bin/sh

set -eo pipefail

PATH=$PATH:/usr/local/bin:/usr/local/opt/gettext/bin:/usr/local/opt/automake/bin:/usr/local/opt/aclocal/bin:/opt/homebrew/bin

XZ_VERSION="v5.8.2"
OPENSSL_VERSION="openssl-3.6.1"
LIBEVENT_VERSION="release-2.1.12-stable"
ATOR_VERSION="v0.4.9.13"


cd "$(dirname "$0")"
ROOT="$(pwd -P)"

DEBUG=""
LZMA="yes"

while getopts dl flag
do
    case "$flag" in
        d) DEBUG="1";;
        l) LZMA="no";;
    esac
done

if [ -z $DEBUG ]; then
    BUILDDIR="$(mktemp -d)"
else
    set -x
    BUILDDIR="$ROOT/build"
    mkdir -p "$BUILDDIR"
fi

echo "Build dir: $BUILDDIR"

build_liblzma() {
    SDK=$1
    ARCH=$2
    MIN=$3

    if [ "$LZMA" != "yes" ]; then
        return
    fi

    SOURCE="$BUILDDIR/xz"
    LOG="$BUILDDIR/liblzma-$SDK-$ARCH.log"

    if [ ! -d "$SOURCE" ]; then
        echo "- Check out XZ project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$XZ_VERSION" https://github.com/tukaani-project/xz.git >> "$LOG" 2>&1
    fi

    echo "- Build liblzma for $ARCH ($SDK)"

    cd "$SOURCE"

    if [ -f Makefile ]; then
        make distclean >> "$LOG" 2>&1
    fi

    # Generate the configure script.
    if [ ! -f ./configure ]; then
        LIBTOOLIZE=glibtoolize
        ./autogen.sh >> "$LOG" 2>&1
    fi

    SDKPATH="$(xcrun --sdk ${SDK} --show-sdk-path)"
    CLANG="$(xcrun -f --sdk ${SDK} clang)"

    ./configure \
        --disable-shared \
        --enable-static \
        --disable-doc \
        --disable-scripts \
        --disable-xz \
        --disable-xzdec \
        --disable-lzmadec \
        --disable-lzmainfo \
        --disable-lzma-links \
        --prefix "$BUILDDIR/$SDK/liblzma-$ARCH" \
        CC="$CLANG -arch ${ARCH}" \
        CPP="$CLANG -E -arch ${ARCH}" \
        CFLAGS="-isysroot ${SDKPATH} -m$SDK-version-min=$MIN -fembed-bitcode -Wno-unknown-warning-option" \
        LDFLAGS="-isysroot ${SDKPATH} -fembed-bitcode" \
        cross_compiling="yes" \
        ac_cv_func_clock_gettime="no" \
        >> "$LOG" 2>&1

    make -j$(sysctl -n hw.logicalcpu_max) >> "$LOG" 2>&1
    make install >> "$LOG" 2>&1
}

build_libssl() {
    SDK=$1
    ARCH=$2
    MIN=$3

    SOURCE="$BUILDDIR/openssl"
    LOG="$BUILDDIR/libssl-$SDK-$ARCH.log"

    if [ ! -d "$SOURCE" ]; then
        echo "- Check out OpenSSL project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$OPENSSL_VERSION" https://github.com/openssl/openssl.git >> "$LOG" 2>&1
    fi

    echo "- Build OpenSSL for $ARCH ($SDK)"

    cd "$SOURCE"

    if [ -f Makefile ]; then
        make distclean >> "$LOG" 2>&1
    fi

    if [ "$SDK" = "iphoneos" ]; then
        if [ "$ARCH" = "arm64" ]; then
            PLATFORM_FLAGS="no-async zlib-dynamic enable-ec_nistp_64_gcc_128"
            CONFIG="ios64-xcrun"
        elif [ "$ARCH" = "armv7" ]; then
            PLATFORM_FLAGS="no-async zlib-dynamic"
            CONFIG="ios-xcrun"
        else
            echo "OpenSSL configuration error: $ARCH on $SDK not supported!"
        fi
    elif [ "$SDK" = "iphonesimulator" ]; then
        if [ "$ARCH" = "arm64" ]; then
            PLATFORM_FLAGS="no-async zlib-dynamic enable-ec_nistp_64_gcc_128"
            CONFIG="iossimulator-xcrun"
        elif [ "$ARCH" = "i386" ]; then
            PLATFORM_FLAGS="no-asm"
            CONFIG="iossimulator-xcrun"
        elif [ "$ARCH" = "x86_64" ]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="iossimulator-xcrun"
        else
            echo "OpenSSL configuration error: $ARCH on $SDK not supported!"
        fi
    elif [ "$SDK" = "macosx" ]; then
        if [ "$ARCH" = "i386" ]; then
            PLATFORM_FLAGS="no-asm"
            CONFIG="darwin-i386-cc"
        elif [ "$ARCH" = "x86_64" ]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="darwin64-x86_64-cc"
        elif [ "$ARCH" = "arm64" ]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="darwin64-arm64-cc"
        else
            echo "OpenSSL configuration error: $ARCH on $SDK not supported!"
        fi
    fi

    if [ -n "$CONFIG" ]; then
        ./Configure \
            no-shared \
            ${PLATFORM_FLAGS} \
            --prefix="$BUILDDIR/$SDK/libssl-$ARCH" \
            ${CONFIG} \
            CC="$(xcrun --sdk $SDK --find clang) -isysroot $(xcrun --sdk $SDK --show-sdk-path) -arch ${ARCH} -m$SDK-version-min=$MIN -fembed-bitcode" \
            >> "$LOG" 2>&1

        make depend >> "$LOG" 2>&1
        make "-j$(sysctl -n hw.logicalcpu_max)" build_libs >> "$LOG" 2>&1
        make install_dev >> "$LOG" 2>&1
    fi
}

build_libevent() {
    SDK=$1
    ARCH=$2
    MIN=$3

    SOURCE="$BUILDDIR/libevent"
    LOG="$BUILDDIR/libevent-$SDK-$ARCH.log"

    if [ ! -d "$SOURCE" ]; then
        echo "- Check out libevent project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$LIBEVENT_VERSION" https://github.com/libevent/libevent.git >> "$LOG" 2>&1
    fi

    echo "- Build libevent for $ARCH ($SDK)"

    cd "$SOURCE"

    if [ -f Makefile ]; then
        make distclean >> "$LOG" 2>&1
    fi

    # Generate the configure script.
    if [ ! -f ./configure ]; then
        ./autogen.sh >> "$LOG" 2>&1
    fi

    CLANG="$(xcrun -f --sdk ${SDK} clang)"
    SDKPATH="$(xcrun --sdk ${SDK} --show-sdk-path)"
    DEST="$BUILDDIR/$SDK/libevent-$ARCH"

    ./configure \
        --disable-shared \
        --disable-openssl \
        --disable-libevent-regress \
        --disable-samples \
        --disable-doxygen-html \
        --enable-static \
        --enable-gcc-hardening \
        --disable-debug-mode \
        --prefix="$DEST" \
        CC="$CLANG -arch ${ARCH}" \
        CPP="$CLANG -E -arch ${ARCH}" \
        CFLAGS="-isysroot ${SDKPATH} -m$SDK-version-min=$MIN -fembed-bitcode" \
        LDFLAGS="-isysroot ${SDKPATH} -L$DEST -fembed-bitcode" \
        cross_compiling="yes" \
        ac_cv_func_clock_gettime="no" \
        ac_cv_func_pipe2="no" \
        >> "$LOG" 2>&1

    make -j$(sysctl -n hw.logicalcpu_max) >> "$LOG" 2>&1
    make install >> "$LOG" 2>&1
}

build_libanon() {
    SDK=$1
    ARCH=$2
    MIN=$3

    SOURCE="$BUILDDIR/ator-protocol"
    LOG="$BUILDDIR/libanon-$SDK-$ARCH.log"

    if [ ! -d "$SOURCE" ]; then
        echo "- Check out ator-protocol project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$ATOR_VERSION" https://github.com/anyone-protocol/ator-protocol.git >> "$LOG" 2>&1
    fi

    echo "- Build libanon for $ARCH ($SDK)"

    cd "$SOURCE"

    if [ -f Makefile ]; then
        make distclean >> "$LOG" 2>&1
    fi

    ## Apply patches:
    git restore . >> "$LOG" 2>&1
    git apply "$ROOT/AnyoneKit/mmap-cache.patch" >> "$LOG" 2>&1

    # Generate the configure script.
    if [ ! -f ./configure ]; then
        # FIXME: This fixes `AnyoneKit/anon/autogen.sh`. Check if that was changed and remove this patch.
        sed -i'.backup' -e 's/all,error/no-obsolete,error/' autogen.sh

        ./autogen.sh >> "$LOG" 2>&1

        # FIXME: Undoes the patch. Remove, when it becomes unnecessary.
        rm autogen.sh && mv autogen.sh.backup autogen.sh
    fi

    CLANG="$(xcrun -f --sdk ${SDK} clang)"
    SDKPATH="$(xcrun --sdk ${SDK} --show-sdk-path)"
    DEST="$BUILDDIR/$SDK/libanon-$ARCH"

    ./configure \
        --enable-silent-rules \
        --enable-pic \
        --disable-module-relay \
        --disable-module-dirauth \
        --disable-tool-name-check \
        --disable-unittests \
        --enable-static-openssl \
        --enable-static-libevent \
        --disable-asciidoc \
        --disable-system-anonrc \
        --disable-linker-hardening \
        --disable-dependency-tracking \
        --disable-manpage \
        --disable-html-manual \
        --disable-gcc-warnings-advisory \
        --enable-lzma="$LZMA" \
        --disable-zstd \
        --with-libevent-dir="$BUILDDIR/$SDK/libevent-$ARCH" \
        --with-openssl-dir="$BUILDDIR/$SDK/libssl-$ARCH" \
        --prefix="$DEST" \
        CC="$CLANG -arch ${ARCH} -isysroot ${SDKPATH}" \
        CPP="$CLANG -E -arch ${ARCH} -isysroot ${SDKPATH}" \
        CPPFLAGS="-fembed-bitcode -Isrc/core -I$BUILDDIR/$SDK/libssl-$ARCH/include -I$BUILDDIR/$SDK/libevent-$ARCH/include -m$SDK-version-min=$MIN" \
        LDFLAGS="-lz -fembed-bitcode" \
        LZMA_CFLAGS="-I$BUILDDIR/$SDK/liblzma-$ARCH/include" \
        LZMA_LIBS="$BUILDDIR/$SDK/liblzma-$ARCH/lib/liblzma.a" \
        cross_compiling="yes" \
        ac_cv_func__NSGetEnviron="no" \
        ac_cv_func_clock_gettime="no" \
        ac_cv_func_getentropy="no" \
        ac_cv_func_pipe2="no" \
        >> "$LOG" 2>&1

    # There seems to be a race condition with the above configure and the later cp.
    # Just sleep a little so the correct file is copied and delete the old one before.
    sleep 2
    rm -f src/lib/cc/orconfig.h >> "$LOG" 2>&1
    cp orconfig.h "src/lib/cc/" >> "$LOG" 2>&1

    make libanon.a -j$(sysctl -n hw.logicalcpu_max) V=1 >> "$LOG" 2>&1

    mkdir -p "$DEST/lib" >> "$LOG" 2>&1
    mkdir -p "$DEST/include" >> "$LOG" 2>&1
    mv libanon.a "$DEST/lib" >> "$LOG" 2>&1
    rsync --archive --include='*.h' -f 'hide,! */' --prune-empty-dirs src/* "$DEST/include" >> "$LOG" 2>&1
    cp orconfig.h "$DEST/include/" >> "$LOG" 2>&1

    mv micro-revision.i "$DEST" >> "$LOG" 2>&1
}

fatten() {
    NAME=$1
    SDK=$2
    LIB=${3:-$NAME}

    if [ "$LZMA" != "yes" -a "$NAME" == "liblzma" ]; then
        return
    fi

    LOG="$BUILDDIR/framework.log"

    echo "- Fatten $LIB in $NAME ($SDK)"

    mkdir -p "$BUILDDIR/$SDK/$NAME/lib" >> "$LOG" 2>&1

    lipo \
        -arch arm64 "$BUILDDIR/$SDK/$NAME-arm64/lib/$LIB.a" \
        -arch x86_64 "$BUILDDIR/$SDK/$NAME-x86_64/lib/$LIB.a" \
        -create -output "$BUILDDIR/$SDK/$NAME/lib/$LIB.a" >> "$LOG" 2>&1
}

write_info_plist() {
    SDK=$1
    NAME=$2
    VERSION=$3

# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/20001431-102088
    cat > "$BUILDDIR/$SDK/$NAME.framework/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$NAME</string>
  <key>CFBundleIdentifier</key>
  <string>io.anyone.$NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$NAME</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>$SDK</string>
  </array>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
</dict>
</plist>
EOF
}

create_framework() {
    SDK=$1
    IS_FAT=$2
    NO_LZMA=$3

    LOG="$BUILDDIR/framework.log"

    if [ -z "$NO_LZMA" ]; then
        NAME="anon"
    else
        NAME="anon-nolzma"
    fi

    rm -rf "$BUILDDIR/$SDK/$NAME.framework" >> "$LOG" 2>&1
    mkdir -p "$BUILDDIR/$SDK/$NAME.framework/Headers" >> "$LOG" 2>&1

    if [ -z "$IS_FAT" ]; then
        echo "- Create framework for $SDK"

        POSTFIX="-arm64"
    else
        echo "- Create framework for fat $SDK"

        POSTFIX=""
    fi

    if [ -z "$NO_LZMA" ]; then
        LIBS=("$BUILDDIR/$SDK/libssl$POSTFIX/lib/libssl.a" \
            "$BUILDDIR/$SDK/libssl$POSTFIX/lib/libcrypto.a" \
            "$BUILDDIR/$SDK/libevent$POSTFIX/lib/libevent.a" \
            "$BUILDDIR/$SDK/liblzma$POSTFIX/lib/liblzma.a" \
            "$BUILDDIR/$SDK/libanon$POSTFIX/lib/libanon.a")
    else
        LIBS=("$BUILDDIR/$SDK/libssl$POSTFIX/lib/libssl.a" \
            "$BUILDDIR/$SDK/libssl$POSTFIX/lib/libcrypto.a" \
            "$BUILDDIR/$SDK/libevent$POSTFIX/lib/libevent.a" \
            "$BUILDDIR/$SDK/libanon-nolzma$POSTFIX/lib/libanon.a")
    fi

    libtool -static -o "$BUILDDIR/$SDK/$NAME.framework/$NAME" "${LIBS[@]}" >> "$LOG" 2>&1

    HEADERS=("$BUILDDIR/$SDK/libssl-arm64/include"/* \
        "$BUILDDIR/$SDK/libevent-arm64/include"/* \
        "$BUILDDIR/$SDK/libanon-arm64/include"/*)

    if [ ! -z "$NO_LZMA" ]; then
        HEADERS=("$BUILDDIR/$SDK/liblzma-arm64/include"/* "${HEADERS[@]}")
    fi

    cp -r "${HEADERS[@]}" "$BUILDDIR/$SDK/$NAME.framework/Headers" >> "$LOG" 2>&1

    write_info_plist "$SDK" "$NAME" "${ATOR_VERSION##*-}"
}

create_xcframework() {
    NAMES=$1

    LOG="$BUILDDIR/framework.log"

    for name in $NAMES
    do
        echo "- Create xcframework for $name"

        rm -rf "$ROOT/$name.xcframework" "$ROOT/$name.xcframework.zip" >> "$LOG" 2>&1

        xcodebuild -create-xcframework \
            -framework "$BUILDDIR/iphoneos/$name.framework" \
            -framework "$BUILDDIR/iphonesimulator/$name.framework" \
            -framework "$BUILDDIR/macosx/$name.framework" \
            -output "$ROOT/$name.xcframework" >> "$LOG" 2>&1

        cd "$ROOT"

        zip -r -9 "$name.xcframework.zip" "$name.xcframework" >> "$LOG" 2>&1
        shasum -a 256 "$name.xcframework.zip"
    done
}

build_liblzma       iphoneos            arm64           15.0
build_libssl        iphoneos            arm64           15.0
build_libevent      iphoneos            arm64           15.0
build_libanon       iphoneos            arm64           15.0
create_framework    iphoneos

build_liblzma       iphonesimulator     arm64           15.0
build_liblzma       iphonesimulator     x86_64          15.0
fatten              liblzma             iphonesimulator
build_libssl        iphonesimulator     arm64           15.0
build_libssl        iphonesimulator     x86_64          15.0
fatten              libssl              iphonesimulator
fatten              libssl              iphonesimulator libcrypto
build_libevent      iphonesimulator     arm64           15.0
build_libevent      iphonesimulator     x86_64          15.0
fatten              libevent            iphonesimulator
build_libanon       iphonesimulator     arm64           15.0
build_libanon       iphonesimulator     x86_64          15.0
fatten              libanon             iphonesimulator
create_framework    iphonesimulator     fat

build_liblzma       macosx              arm64           11.0
build_liblzma       macosx              x86_64          11.0
fatten              liblzma             macosx
build_libssl        macosx              arm64           11.0
build_libssl        macosx              x86_64          11.0
fatten              libssl              macosx
fatten              libssl              macosx          libcrypto
build_libevent      macosx              arm64           11.0
build_libevent      macosx              x86_64          11.0
fatten              libevent            macosx
build_libanon       macosx              arm64           11.0
build_libanon       macosx              x86_64          11.0
fatten              libanon             macosx
create_framework    macosx              fat
create_xcframework  "anon"

if [ -z $DEBUG ]; then
    rm -rf "$BUILDDIR"
fi
