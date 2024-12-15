# Use slim Debian image for smaller footprint
FROM debian:bullseye

# Update package lists before installing dependencies
RUN apt-get update && apt-get upgrade -y

# Install dependencies for Tor, obfs4proxy and GeoIP
RUN apt-get install -y --no-install-recommends \
  wget \
  make \
  gcc \
  libevent-dev \
  libssl-dev \
  gnupg \
  zlib1g-dev \
  tor/bullseye-backports \
  tor-geoipdb/bullseye-backports \
  obfs4proxy/bullseye-backports

# Install utilities for additional tasks (optional)
RUN apt-get install -y --no-install-recommends \
  pwgen \
  iputils-ping \
  nano \
  neofetch (optional)

# Download and verify Tor source code (if TOR_VERSION is not set)
ENV TOR_VERSION \
  wget -qO- https://www.torproject.org/dist/tor-stable.tar.gz.asc | \
  gpg --keyserver keyserver.openpgp.org --recv-keys 88B22BB3C9F79F388C472F02D09EFB0C876D4BD8 | \
  gpg --verify - | grep -oP '(?<=tor-).*(?=\.tar\.gz)'


ENV TOR_TARBALL_NAME="tor-${TOR_VERSION}.tar.gz"
ENV TOR_TARBALL_LINK="https://dist.torproject.org/${TOR_TARBALL_NAME}"
ENV TOR_TARBALL_ASC="${TOR_TARBALL_NAME}.asc"

RUN wget -qO- "$TOR_TARBALL_LINK" \
  && wget -qO- "$TOR_TARBALL_ASC" \
  && gpg --verify "$TOR_TARBALL_ASC" "$TOR_TARBALL_NAME" \
  && tar -xzf "$TOR_TARBALL_NAME" \
  && cd "tor-$TOR_VERSION" \
  && ./configure \
  && make -j$(nproc) \
  && make install \
  && cd .. \
  && rm -rf "tor-$TOR_VERSION" \
  && rm "$TOR_TARBALL_NAME" "$TOR_TARBALL_ASC"

# Configure Tor (replace with your own torrc)
COPY ./torrc /etc/tor/torrc

# Rename Debian unprivileged user to tord
RUN usermod -l ${TOR_USER} debian-tor && groupmod -n ${TOR_USER} debian-tor

# Persist data volumes and expose ports
VOLUME /etc/tor /var/lib/tor
#optional
EXPOSE 9001 9030 9050 54444 7002

# Entrypoint script (replace with your own)
COPY ./scripts/ /usr/local/bin/

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]