# Dockerfile for Tor Relay Server with obfs4proxy
FROM debian:bullseye
RUN echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list
#MAINTAINER Kevan kevdude18@gmail.com

ARG GPGKEY=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="True"
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND=noninteractive
ARG found=""

# Set a default Nickname
ENV TOR_NICKNAME=Tor4
ENV TOR_USER=tord
ENV TERM=xterm

ENV TOR_VERSION $TOR_VERSION
ENV TOR_TARBALL_NAME tor-\$TOR_VERSION.tar.gz
ENV TOR_TARBALL_LINK https://dist.torproject.org/\$TOR_TARBALL_NAME
ENV TOR_TARBALL_ASC \$TOR_TARBALL_NAME.asc

RUN \\
       apt-get update \\
       && apt-get -y upgrade \\
       && apt-get -y install \\
       wget \\
       make \\
       gcc \\
       libevent-dev \\
       libssl-dev \\
       gnupg \\
       zlib1g-dev \\
       && apt-get clean

RUN \\
       wget \$TOR_TARBALL_LINK \\
       && wget \$TOR_TARBALL_LINK.asc \\
       && gpg --keyserver keys.openpgp.org --recv-keys 7A02B3521DC75C542BA015456AFEE6D49E92B601 \\
       && gpg --verify \$TOR_TARBALL_NAME.asc \\
       && tar xvf \$TOR_TARBALL_NAME \\
       && cd tor-\$TOR_VERSION \\
       && ./configure \\
       && make \\
       && make install \\
       && cd .. \\
       && rm -r tor-\$TOR_VERSION \\
       && rm \$TOR_TARBALL_NAME \\
       && rm \$TOR_TARBALL_NAME.asc

# Install tor with GeoIP and obfs4proxy & backup torrc
RUN apt-get update \
       && apt-get install -y --no-install-recommends \
       apt-utils \
       && apt-get install -y --no-install-recommends \
       pwgen \
       iputils-ping \
       nano \
       neofetch \
       tor/bullseye-backports \
       tor-geoipdb/bullseye-backports \
       obfs4proxy/bullseye-backports \
       && mkdir -pv /usr/local/etc/tor/ \
       && mv -v /etc/tor/torrc /usr/local/etc/tor/torrc.sample \
       && apt-get purge --auto-remove -y \
       apt-utils \
       && apt-get clean \
       && rm -rf /var/lib/apt/lists/* \
       # Rename Debian unprivileged user to tord \
       && usermod -l ${TOR_USER} debian-tor \
       && groupmod -n ${TOR_USER} debian-tor

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
