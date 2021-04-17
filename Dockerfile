FROM debian:buster-slim AS build

RUN set -ex \
    && sed -ni.bak 'p; s/^deb /deb-src /p' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y build-essential libboost-all-dev libluajit-5.1-dev libprotobuf-dev libsodium-dev libssl-dev pkg-config protobuf-compiler \
    && apt-get install -y curl

ARG BUILD_CONCURRENT=1

ARG RECURSOR_URL=https://downloads.powerdns.com/releases/pdns-recursor-4.4.3.tar.bz2
ARG RECURSOR_SHA256=f8411258100cc310c75710d7f4d59b5eb4797f437f71dc466ed97a83f1babe05

WORKDIR /usr/local/src/pdns-recursor

RUN set -ex \
    && curl -fsSL --retry 3 "${RECURSOR_URL}" -o recursor.tar.bz2 \
    && echo "${RECURSOR_SHA256}  recursor.tar.bz2" | sha256sum -c - \
    && tar xf recursor.tar.bz2 --strip 1

RUN ./configure \
    --disable-systemd \
    --enable-reproducible \
    --enable-static-boost \
    --with-lua \
    --with-protobuf \
    --with-libsodium

RUN make -j ${BUILD_CONCURRENT} && make install DESTDIR=/output

################################################################################

FROM debian:buster-slim

COPY --from=build /output /

RUN set -ex \
    && apt-get update \
    && apt-get install -y dns-root-data libboost-context1.67.0 libboost-filesystem1.67.0 libluajit-5.1 libprotobuf17 libsodium23 libssl1.1 python3 python3-pip tini \
    && python3 -m pip install envtpl \
    && apt-get remove --purge -y python3-pip \
    && apt-get autoremove -y

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY recursor.conf.tpl /usr/local/etc/recursor.conf.tpl
RUN chmod +x /docker-entrypoint.sh
RUN mkdir -p /var/run/pdns-recursor

ENTRYPOINT [ "/usr/bin/tini", "--", "/docker-entrypoint.sh" ]

CMD [ "/usr/local/sbin/pdns_recursor", "--hint-file=/usr/share/dns/root.hints" ]
