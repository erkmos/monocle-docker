FROM ubuntu:14.04 as builder
ENV TERM linux

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:bitcoin/bitcoin && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        wget \
        libboost-system1.55-dev \
        libboost-filesystem1.55-dev \
        libboost-chrono1.55-dev \
        libboost-test1.55-dev \
        libboost-thread1.55-dev \
        libboost-program-options1.55-dev \
        build-essential \
        libdb4.8-dev \
        libdb4.8++-dev \
        zlib1g-dev \
        autoconf \
        pkg-config \
        libssl-dev \
        libtool

ENV MONOCLE_VERSION 0.8.7.1b

# build monocled
WORKDIR /build
RUN wget -q https://github.com/monocle-project/monocle/archive/v$MONOCLE_VERSION.tar.gz && \
    tar zxf v$MONOCLE_VERSION.tar.gz && \
    mv monocle-$MONOCLE_VERSION monocle && \
    cd monocle/src && \
    make -j `nproc` -f makefile.unix \
      USE_UPNP=- USE_IPV6=1 USE_SSE2=1 STATIC=1 && \
    strip monocled && \
    echo "printtoconsole=1\nserver=1\ndaemon=0\nlisten=1\nrpcuser=donkey\ntxindex=1" > monocle.conf && \
    echo "rpcpassword=$(openssl rand -hex 16)" >> monocle.conf

FROM debian:stable-slim

COPY --from=builder /build/monocle/src/monocled /usr/bin/monocled
COPY --from=builder /build/monocle/src/monocle.conf /etc/monocle.conf

EXPOSE 6889 6888

ENTRYPOINT ["monocled", "-conf=/etc/monocle.conf", "-datadir=/data"]
