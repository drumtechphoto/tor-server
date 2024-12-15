FROM debian:bookworm AS builder

# Install required packages
RUN apt-get update && apt-get install -y \
       wget tar gzip build-essential libevent-dev libssl-dev zlib1g zlib1g-dev pwgen iputils-ping nano neofetch tor-geoipdb obfs4proxy

# Download and extract Tor source code
WORKDIR /tmp
RUN wget --no-check-certificate https://dist.torproject.org/tor-0.4.8.9.tar.gz
RUN tar -xzf tor-0.4.8.9.tar.gz

# Build Tor
WORKDIR /tmp/tor-0.4.8.9
RUN ./configure --prefix=/usr/local
RUN make -j $(nproc)
RUN make install

# Stage 2: Final image
FROM debian:bookworm

# Install dependencies
RUN apt-get update && apt-get upgrade -y


# Copy Tor binaries and configuration
COPY --from=builder /usr/local/bin/tor /usr/local/bin/
#COPY --from=builder /usr/local/sbin/tor /usr/local/sbin/
COPY --from=builder /usr/local/share/tor /usr/local/share/tor
COPY --from=builder /usr/local/etc/tor /usr/local/etc/tor

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint script
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Expose ports
EXPOSE 9001 9030 9050 54444 7002

CMD ["tor", "-f", "/etc/tor/torrc"]