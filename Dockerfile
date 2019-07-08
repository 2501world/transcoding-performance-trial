ARG FFMPEG_VERSION=4.1.3

###############################
# Build the FFmpeg-build image.
FROM alpine:3.9 as build-ffmpeg

ARG FFMPEG_VERSION
ARG PREFIX=/usr/local
ARG MAKEFLAGS="-j4"

# FFmpeg build dependencies.
RUN apk add --update --no-cache \
    build-base \
    coreutils \
    pkgconf \
    pkgconfig \
    wget \
    x264-dev \
    yasm

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

# Get FFmpeg source.
RUN cd /tmp/ \
    && wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz \
    && tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} \
    && ./configure \
        --prefix=${PREFIX} \
        --enable-version3 \
        --enable-gpl \
        --enable-nonfree \
        --enable-small \
        --enable-libx264 \
        --enable-postproc \
        --enable-avresample \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --extra-libs="-lpthread -lm" \
    && make \
    && make install \
    && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.9

RUN apk add --update --no-cache \
    curl \
    dmidecode \
    jq \
    x264-dev

COPY --from=build-ffmpeg /usr/local /usr/local

ADD ./bin /opt/bin

ENTRYPOINT ["/opt/bin/main.sh"]
