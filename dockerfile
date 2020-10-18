FROM php:cli-buster

RUN apt-get update && apt-get install -y build-essential curl git python libglib2.0-dev patchelf; \
    cd /tmp; \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git; \
    export PATH=`pwd`/depot_tools:"$PATH"; \
    fetch v8; \
    cd v8; \
    git checkout 8.0.426.30; \
    gclient sync; \
    tools/dev/v8gen.py -vv x64.release -- is_component_build=true use_custom_libcxx=false; \
    ninja -C out.gn/x64.release/; \
    mkdir -p /usr/local/v8/lib; \
    mkdir -p /usr/local/v8/include; \
    cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin \
        out.gn/x64.release/icudtl.dat /usr/local/v8/lib/; \
    cp -R include/* /usr/local/v8/include/; \
    for A in /usr/local/v8/lib/*.so; do patchelf --set-rpath '$ORIGIN' $A; done; \
    cd /tmp; \
    git clone https://github.com/phpv8/v8js.git; \
    cd v8js; \
    phpize; \
    ./configure --with-v8js=/usr/local/v8 LDFLAGS="-lstdc++" CPPFLAGS="-DV8_COMPRESS_POINTERS"; \
    make; \
    make install; \
    rm -rf /tmp/v8js /tmp/v8 /tmp/depot_tools; \
    apt-get remove build-essential patchelf libglib2.0-dev -y; \
    apt-get autoremove --purge -y; \
    apt-get clean -y; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    docker-php-ext-enable v8js.so;