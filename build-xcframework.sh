#!/bin/sh

PATH=$PATH:/usr/local/bin:/usr/local/opt/gettext/bin:/usr/local/opt/automake/bin:/usr/local/opt/aclocal/bin:/opt/homebrew/bin

XZ_VERSION="v5.6.3"
OPENSSL_VERSION="openssl-3.4.0"
LIBEVENT_VERSION="release-2.1.12-stable"
ATOR_VERSION="main"

cd "$(dirname "$0")"
ROOT="$(pwd -P)"
BUILDDIR="$(mktemp -d)"

echo "Build dir: $BUILDDIR"

build_liblzma() {
    SDK=$1
    ARCH=$2
    MIN=$3

    SOURCE="$BUILDDIR/xz"
    LOG="$BUILDDIR/liblzma-$SDK-$ARCH.log"

    if [[ ! -d "$SOURCE" ]]; then
        echo "- Check out XZ project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$XZ_VERSION" https://github.com/tukaani-project/xz.git >> "$LOG" 2>&1
    fi

    echo "- Build liblzma for $ARCH ($SDK)"

    cd "$SOURCE"

    make distclean 2>/dev/null 1>/dev/null

    # Generate the configure script.
    if [[ ! -f ./configure ]]; then
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

    if [[ ! -d "$SOURCE" ]]; then
        echo "- Check out OpenSSL project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$OPENSSL_VERSION" https://github.com/openssl/openssl.git >> "$LOG" 2>&1
    fi

    echo "- Build OpenSSL for $ARCH ($SDK)"

    cd "$SOURCE"

    make distclean 2>/dev/null 1>/dev/null

    if [[ "${SDK}" == "iphoneos" ]]; then
        if [[ "${ARCH}" == "arm64" ]]; then
            PLATFORM_FLAGS="no-async zlib-dynamic enable-ec_nistp_64_gcc_128"
            CONFIG="ios64-xcrun"
        elif [[ "${ARCH}" == "armv7" ]]; then
            PLATFORM_FLAGS="no-async zlib-dynamic"
            CONFIG="ios-xcrun"
        else
            echo "OpenSSL configuration error: ${ARCH} on ${PLATFORM_NAME} not supported!"
        fi
    elif [[ "${SDK}" == "iphonesimulator" ]]; then
        if [[ "${ARCH}" == "arm64" ]]; then
            PLATFORM_FLAGS="no-async zlib-dynamic enable-ec_nistp_64_gcc_128"
            CONFIG="iossimulator-xcrun"
        elif [[ "${ARCH}" == "i386" ]]; then
            PLATFORM_FLAGS="no-asm"
            CONFIG="iossimulator-xcrun"
        elif [[ "${ARCH}" == "x86_64" ]]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="iossimulator-xcrun"
        else
            echo "OpenSSL configuration error: ${ARCH} on ${PLATFORM_NAME} not supported!"
        fi
    elif [[ "${SDK}" == "macosx" ]]; then
        if [[ "${ARCH}" == "i386" ]]; then
            PLATFORM_FLAGS="no-asm"
            CONFIG="darwin-i386-cc"
        elif [[ "${ARCH}" == "x86_64" ]]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="darwin64-x86_64-cc"
        elif [[ "${ARCH}" == "arm64" ]]; then
            PLATFORM_FLAGS="no-asm enable-ec_nistp_64_gcc_128"
            CONFIG="darwin64-arm64-cc"
        else
            echo "OpenSSL configuration error: ${ARCH} on ${PLATFORM_NAME} not supported!"
        fi
    fi

    if [ -n "${CONFIG}" ]; then
        ./Configure \
            no-shared \
            ${PLATFORM_FLAGS} \
            --prefix="$BUILDDIR/$SDK/libssl-$ARCH" \
            ${CONFIG} \
            CC="$(xcrun --sdk ${SDK} --find clang) -isysroot $(xcrun --sdk ${SDK} --show-sdk-path) -arch ${ARCH} -m$SDK-version-min=$MIN -fembed-bitcode" \
            >> "$LOG" 2>&1

        make depend >> "$LOG" 2>&1
        make -j$(sysctl -n hw.logicalcpu_max) build_libs >> "$LOG" 2>&1
        make install_dev >> "$LOG" 2>&1
    fi
}

build_libevent() {
    SDK=$1
    ARCH=$2
    MIN=$3

    SOURCE="$BUILDDIR/libevent"
    LOG="$BUILDDIR/libevent-$SDK-$ARCH.log"

    if [[ ! -d "$SOURCE" ]]; then
        echo "- Check out libevent project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$LIBEVENT_VERSION" https://github.com/libevent/libevent.git >> "$LOG" 2>&1
    fi

    echo "- Build libevent for $ARCH ($SDK)"

    cd "$SOURCE"

    make distclean 2>/dev/null 1>/dev/null

    # Generate the configure script.
    if [[ ! -f ./configure ]]; then
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

    if [[ ! -d "$SOURCE" ]]; then
        echo "- Check out ator-protocol project"

        cd "$BUILDDIR"
        git clone --recursive --shallow-submodules --depth 1 --branch "$ATOR_VERSION" https://github.com/anyone-protocol/ator-protocol.git >> "$LOG" 2>&1
    fi

    echo "- Build libanon for $ARCH ($SDK)"

    cd "$SOURCE"

    make distclean 2>/dev/null 1>/dev/null

    ## Apply patches:
    git apply --quiet "$ROOT/AnyoneKit/mmap-cache.patch"

    # Generate the configure script.
    if [[ ! -f ./configure ]]; then
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
        --enable-lzma \
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

    echo "- Fatten $LIB in $NAME ($SDK)"

    mkdir -p "$BUILDDIR/$SDK/$NAME/lib"

    lipo \
        -arch arm64 "$BUILDDIR/$SDK/$NAME-arm64/lib/$LIB.a" \
        -arch x86_64 "$BUILDDIR/$SDK/$NAME-x86_64/lib/$LIB.a" \
        -create -output "$BUILDDIR/$SDK/$NAME/lib/$LIB.a"
}

create_framework() {
    SDK=$1
    IS_FAT=$2

    mkdir -p "$BUILDDIR/$SDK/anon.framework/Headers"

    if [[ -z "$IS_FAT" ]]; then
        echo "- Create framework for $SDK"

        libtool -static -o "$BUILDDIR/$SDK/anon.framework/anon" \
            "$BUILDDIR/$SDK/liblzma-arm64/lib/liblzma.a" \
            "$BUILDDIR/$SDK/libssl-arm64/lib/libssl.a" \
            "$BUILDDIR/$SDK/libssl-arm64/lib/libcrypto.a" \
            "$BUILDDIR/$SDK/libevent-arm64/lib/libevent.a" \
            "$BUILDDIR/$SDK/libanon-arm64/lib/libanon.a"
    else
        echo "- Create framework for fat $SDK"

        libtool -static -o "$BUILDDIR/$SDK/anon.framework/anon" \
            "$BUILDDIR/$SDK/liblzma/lib/liblzma.a" \
            "$BUILDDIR/$SDK/libssl/lib/libssl.a" \
            "$BUILDDIR/$SDK/libssl/lib/libcrypto.a" \
            "$BUILDDIR/$SDK/libevent/lib/libevent.a" \
            "$BUILDDIR/$SDK/libanon/lib/libanon.a"
    fi

    cp -r "$BUILDDIR/$SDK/liblzma-arm64/include"/* \
        "$BUILDDIR/$SDK/libssl-arm64/include"/* \
        "$BUILDDIR/$SDK/libevent-arm64/include"/* \
        "$BUILDDIR/$SDK/libanon-arm64/include"/* \
        "$BUILDDIR/$SDK/anon.framework/Headers"
}

build_liblzma       iphoneos            arm64           12.0
build_libssl        iphoneos            arm64           12.0
build_libevent      iphoneos            arm64           12.0
build_libanon       iphoneos            arm64           12.0
create_framework    iphoneos

build_liblzma       iphonesimulator     arm64           12.0
build_liblzma       iphonesimulator     x86_64          12.0
fatten              liblzma             iphonesimulator
build_libssl        iphonesimulator     arm64           12.0
build_libssl        iphonesimulator     x86_64          12.0
fatten              libssl              iphonesimulator
fatten              libssl              iphonesimulator libcrypto
build_libevent      iphonesimulator     arm64           12.0
build_libevent      iphonesimulator     x86_64          12.0
fatten              libevent            iphonesimulator
build_libanon       iphonesimulator     arm64           12.0
build_libanon       iphonesimulator     x86_64          12.0
fatten              libanon             iphonesimulator
create_framework    iphonesimulator     fat

build_liblzma       macosx              arm64           10.13
build_liblzma       macosx              x86_64          10.13
fatten              liblzma             macosx
build_libssl        macosx              arm64           10.13
build_libssl        macosx              x86_64          10.13
fatten              libssl              macosx
fatten              libssl              macosx          libcrypto
build_libevent      macosx              arm64           10.13
build_libevent      macosx              x86_64          10.13
fatten              libevent            macosx
build_libanon       macosx              arm64           10.13
build_libanon       macosx              x86_64          10.13
fatten              libanon             macosx
create_framework    macosx              fat

echo "- Create xcframework"

rm -rf "$ROOT/anon.xcframework"

xcodebuild -create-xcframework \
    -framework "$BUILDDIR/iphoneos/anon.framework" \
    -framework "$BUILDDIR/iphonesimulator/anon.framework" \
    -framework "$BUILDDIR/macosx/anon.framework" \
    -output "$ROOT/anon.xcframework"

rm -rf "$BUILDDIR"
