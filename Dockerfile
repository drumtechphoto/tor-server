# Stage 1: Build Tor from source
FROM debian:bullseye AS builder

ARG GPGKEY=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="True"
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND=noninteractive
ARG TOR_VERSION=0.4.9.1-alpha  # Specify the desired Tor version

ENV TOR_TARBALL_NAME tor-$TOR_VERSION.tar.gz
ENV TOR_TARBALL_LINK https://dist.torproject.org/$TOR_TARBALL_NAME
ENV TOR_TARBALL_ASC $TOR_TARBALL_NAME.asc

RUN echo 'deb http://http.us.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list
RUN echo 'deb http://deb.debian.org/debian bullseye-backports-sloppy main' > /etc/apt/sources.list.d/backports.list

RUN apt-get update -y
RUN apt-get install -y wget make gcc libevent-dev libssl-dev gnupg zlib1g-dev

RUN wget -qO- $TOR_TARBALL_LINK | tar -xzf -
RUN wget -qO- $TOR_TARBALL_ASC | gpg --keyserver keys.openpgp.org --recv-keys 0x$GPGKEY
RUN gpg --verify $TOR_TARBALL_NAME.asc $TOR_TARBALL_NAME

RUN cd tor-$TOR_VERSION
RUN ./configure
RUN make -j $(nproc)
RUN make install

# Stage 2: Final image
FROM debian:bullseye

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends pwgen iputils-ping nano neofetch tor-geoipdb
RUN apt-get update
RUN apt-get install -y obfs4proxy

COPY --from=builder /usr/local/bin/tor /usr/local/bin/
COPY --from=builder /usr/local/sbin/tor /usr/local/sbin/
COPY --from=builder /usr/local/share/tor /usr/local/share/tor
COPY --from=builder /usr/local/etc/tor /usr/local/etc/tor

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort, MeekPort
EXPOSE 9001 9030 9050 54444 7002

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]