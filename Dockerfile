FROM debian AS builder

# Install dependencies
RUN apt-get update
RUN apt-get install -y \
 grep build-essential gcc g++ automake libboost-all-dev \
 git-core autoconf make patch cmake libmariadb-dev libmariadb-dev-compat \
 mariadb-server libtool libssl-dev binutils libc6 libbz2-dev subversion

# Acquire source code
WORKDIR /src/cmangos-classic
RUN git clone --depth 1 https://github.com/cmangos/mangos-classic.git mangos
WORKDIR /src/cmangos-classic/mangos
RUN git clone --depth 1 https://github.com/cmangos/classic-db.git

# Build cmangos
WORKDIR /src/cmangos-classic/mangos/build
RUN cmake /src/cmangos-classic/mangos \
 -DCMAKE_INSTALL_PREFIX=/opt/cmangos-classic -DPCH=1 -DDEBUG=0 \
 -DBUILD_PLAYERBOTS=ON -DBUILD_AHBOT=ON -DBUILD_METRICS=ON

# Install cmangos
RUN make -j$(nproc) install
RUN cp /opt/cmangos-classic/ahbot.conf.dist /opt/cmangos-classic/ahbot.conf && \
 && cp /opt/cmangos-classic/aiplayerbot.conf.dist /opt/cmangos-classic/aiplayerbot.conf \
 && cp /opt/cmangos-classic/anticheat.conf.dist /opt/cmangos-classic/anticheat.conf \
 && cp /opt/cmangos-classic/mangosd.conf.dist /opt/cmangos-classic/mangosd.conf \
 && cp /opt/cmangos-classic/realmd.conf.dist /opt/cmangos-classic/realmd.conf

FROM debian AS runner

# Copy cmangos from build container
COPY --from=builder /opt/cmangos-classic /opt/cmangos-classic

# Acquire runtime dependencies
RUN apt-get update && apt-get install -y \
 libssl3 libmariadb3 \
 && rm -rf /var/lib/apt/lists/*

# Run cmangosd
WORKDIR /opt/cmangos-classic
EXPOSE 3724/tcp
EXPOSE 8085/tcp
ENTRYPOINT ["/opt/cmangos-classic/bin/mangosd"]
