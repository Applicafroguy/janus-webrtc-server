FROM     ubuntu:18.04

### build tools ###
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    aptitude \
    cmake

### Utils ###
RUN apt-get update && aptitude install -y \
    curl \
    psmisc \
    nano \
    git \
    wget \
    unzip \
    python 

###sipre plugin (dev stage)###
#RUN wget http://creytiv.com/pub/re-0.5.3.tar.gz && tar xvf re-0.5.3.tar.gz && \
#	cd re-0.5.3 && \
#	wget https://raw.githubusercontent.com/alfredh/patches/master/re-sip-trace.patch && \
#	ls && \
#	make clean && \
#       patch -p0 -u < re-sip-trace.patch && \
#	make && \
#	make install 
#	nm /usr/local/lib/libre.so | grep tls_alloc

### Janus ###
RUN aptitude install -y\
    libmicrohttpd-dev \
    libjansson-dev \
    libssl-dev \
    libsrtp-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \ 
    libcurl4-openssl-dev \ 
    liblua5.3-dev \
    libconfig-dev \
    pkg-config \ 
    gengetopt \
    libtool \ 
    gtk-doc-tools \
    gettext \
    gettext-base \
    automake
RUN cd /root && git clone https://gitlab.freedesktop.org/libnice/libnice.git && \
    cd libnice && \
    bash autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install

RUN cd /root && SRTP="2.2.0" && apt-get remove -y libsrtp0-dev && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install

RUN cd /root && LIBWEBSOCKET="3.1.0" && wget https://github.com/warmcat/libwebsockets/archive/v$LIBWEBSOCKET.tar.gz && \
    tar xzvf v$LIBWEBSOCKET.tar.gz && \
    cd libwebsockets-$LIBWEBSOCKET && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_MAX_SMP=1 -DLWS_IPV6="ON" .. && \
    make && make install

# RUN cd /root && wget http://conf.meetecho.com/sofiasip/sofia-sip-1.12.11.tar.gz && \
#     tar xfv sofia-sip-1.12.11.tar.gz && \
#     cd sofia-sip-1.12.11 && \
#     wget http://conf.meetecho.com/sofiasip/0001-fix-undefined-behaviour.patch && \
#     wget http://conf.meetecho.com/sofiasip/sofiasip-semicolon-authfix.diff && \
#     patch -p1 -u < 0001-fix-undefined-behaviour.patch && \
#     patch -p1 -u < sofiasip-semicolon-authfix.diff && \
#     ./configure --prefix=/usr && \
#     make && make install
RUN cd /root && git clone https://github.com/meetecho/janus-gateway.git --depth 1 && \
    cd /root/janus-gateway && \
    git fetch --unshallow && \
    ./autogen.sh && \
    ./configure \
    --prefix=/opt/janus \
    --disable-docs \
    --disable-websockets \
    --enable-plugin-videoroom \
    --disable-plugin-streaming \
    --disable-plugin-audiobridge \
    --disable-plugin-textroom \
    --enable-plugin-recordplay \
    --disable-plugin-videocall \
    --disable-plugin-voicemail \
    --disable-rabbitmq \
    --disable-mqtt \
    --disable-plugin-sip \
    --disable-unix-sockets \
    --disable-plugin-nosip \ 
    --disable-boringssl \
    --disable-data-channels && \
    make && \
    make install && \
    make configs
# RUN sed -i "s/admin_http = no/admin_http = yes/g" /opt/janus/etc/janus/janus.transport.http.cfg
# RUN sed -i "s/https = no/https = yes/g" /opt/janus/etc/janus/janus.transport.http.cfg
# RUN sed -i "s/;secure_port = 8089/secure_port = 8089/g" /opt/janus/etc/janus/janus.transport.http.cfg
# RUN sed -i "s/wss = no/wss = yes/g" /opt/janus/etc/janus/janus.transport.websockets.cfg
# RUN sed -i "s/;wss_port = 8989/wss_port = 8989/g" /opt/janus/etc/janus/janus.transport.websockets.cfg
# RUN sed -i "s/enabled = no/enabled = yes/g" /opt/janus/etc/janus/janus.eventhandler.sampleevh.cfg
# RUN sed -i "s\^backend.*path$\backend = http://janus.click2vox.io:7777\g" /opt/janus/etc/janus/janus.eventhandler.sampleevh.cfg
# RUN sed -i s/grouping = yes/grouping = no/g /opt/janus/etc/janus/janus.eventhandler.sampleevh.cfg
# RUN sed -i "s/behind_nat = no/behind_nat = yes/g" /opt/janus/etc/janus/janus.plugin.sip.cfg
# RUN sed -i "s/;rtp_port_range = 20000-40000/rtp_port_range = 10000-10200/g" /opt/janus/etc/janus/janus.cfg

### Cleaning ###
RUN apt-get clean -y && apt-get autoclean && apt-get autoremove -y

ENTRYPOINT ["/opt/janus/bin/janus"]