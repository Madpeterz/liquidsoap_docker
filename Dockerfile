# syntax=docker/dockerfile:1.7

ARG UBUNTU_CODENAME=noble
ARG LIQ_VERSION=2.4.4
ARG LIQ_DISTRO=ubuntu-noble
ARG LIQ_OCAML=4.14.2

FROM ubuntu:${UBUNTU_CODENAME}
ARG DEBIAN_FRONTEND=noninteractive

COPY vendor/liquidsoap_2.4.4-ubuntu-noble-ocaml4.14.2-1_amd64.deb /tmp/liquidsoap.deb
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates /tmp/liquidsoap.deb \
 && rm -rf /var/lib/apt/lists/* /tmp/liquidsoap.deb \
 && chmod +x /usr/local/bin/entrypoint.sh \
 && mkdir -p /data

WORKDIR /app

ENV LIQ_SOURCE_MODE=single \
    LIQ_SOURCE_URI=/data/stream.mp3 \
    LIQ_NEXT_SONG_URL= \
    LIQ_OUTPUT_SERVER=shoutcast2 \
    ICECAST_HOST=icecast \
    ICECAST_PORT=8000 \
    ICECAST_USER=source \
    ICECAST_PASSWORD=hackme \
    ICECAST_MOUNT=/stream.mp3 \
    ICECAST_PROTOCOL= \
    ICECAST_NAME=Liquidsoap \
    ICECAST_DESCRIPTION="Liquidsoap stream" \
    ICECAST_GENRE=Radio \
    ICECAST_URL=http://localhost \
    ICECAST_PUBLIC=false \
    ICECAST_BITRATE=128

VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]