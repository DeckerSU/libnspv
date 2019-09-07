#!/bin/bash
# [TEST] build script for libnSPV with Emscripten 

curdir=$(pwd)
stagedir=${curdir}/depends-emcc-stage
installdir=${curdir}/depends-emcc

mkdir -p ${stagedir}
mkdir -p ${installdir}

#if false; then
# *** compile libevent to bitcode ***
    cd ${stagedir}
    wget -nc https://github.com/libevent/libevent/archive/release-2.1.7-rc.tar.gz
    tar xzvf release-2.1.7-rc.tar.gz 
    cd libevent-release-2.1.7-rc
    ./autogen.sh

    emconfigure ./configure --disable-shared --disable-openssl --disable-debug-mode --with-pic --prefix=${installdir}
    # --disable-thread-support --disable-libevent-regress
    sed -i.bak -e 's/#define HAVE_ARC4RANDOM 1/\/\/ #define HAVE_ARC4RANDOM 0/' ./config.h
    emmake make V=1
    emmake make install

# *** compile libsodium to bitcode ***
    cd ${stagedir}
    wget -nc https://download.libsodium.org/libsodium/releases/old/libsodium-1.0.15.tar.gz
    tar xzvf libsodium-1.0.15.tar.gz
    cd libsodium-1.0.15
    ./autogen.sh
    emconfigure ./configure --enable-static --disable-shared --prefix=${installdir}
    emmake make V=1
    emmake make install
#fi

cd ${curdir}

# https://github.com/cliqz-oss/ceba.js/blob/master/build.sh
# https://github.com/emscripten-core/emscripten/issues/6503

# https://stackoverflow.com/questions/55795238/problem-connecting-websocket-from-c-compiled-with-emscripten
# https://blog.squareys.de/emscripten-sockets/
# https://github.com/emscripten-core/emscripten/tree/master/tests/sockets

./autogen.sh
# configure.ac seems don't support pkg-config for libevent, TODO: fix
CPPFLAGS="-I${installdir}/include" LDFLAGS="-L${installdir}/lib" emconfigure ./configure --prefix=${installdir} \
    PKG_CONFIG_PATH="${installdir}/lib/pkgconfig" \
    --disable-shared --enable-static
emmake make VERBOSE=1
emmake make install VERBOSE=1
cd ${installdir}/bin

ln -s -f bitcoin-send-tx bitcoin-send-tx.bc
ln -s -f bitcoin-spv bitcoin-spv.bc
ln -s -f bitcointool bitcointool.bc
ln -s -f nspv nspv.bc

# TODO: solve tdelete, tfind, tsearch issue at link stage (search.h)
# http://man7.org/linux/man-pages/man3/tsearch.3.html
# we should include tsearch_avl.c in libbtc_la_SOURCES for Emscripten Build

echo --- bitcoin-send-tx
emcc bitcoin-send-tx.bc -s WASM=1 -o bitcoin-send-tx.html
echo --- bitcoin-spv
emcc bitcoin-spv.bc -s WASM=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -o bitcoin-spv.html
echo --- bitcointool
emcc bitcointool.bc -s WASM=1 -o bitcointool.html
echo --- nspv
emcc nspv.bc -s WASM=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -o nspv.html


