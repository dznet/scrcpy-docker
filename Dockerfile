### builder
FROM alpine:edge AS builder

ARG SCRCPY_VER=1.5
ARG SERVER_HASH="d97aab6f60294e33e7ff79c2856ad3e01f912892395131f4f337e9ece03c24de"

RUN apk add --no-cache \
        curl \
        ffmpeg-dev \
        gcc \
        git \
        make \
        meson \
        musl-dev \
        openjdk8 \
        pkgconf \
        sdl2-dev

RUN PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/bin
# TODO: remove 'fixversion' for next release
RUN curl -L -o scrcpy-server.jar https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VER}-fixversion/scrcpy-server-v${SCRCPY_VER}.jar
RUN echo "$SERVER_HASH  /scrcpy-server.jar" | sha256sum -c -
RUN git clone https://github.com/Genymobile/scrcpy.git
RUN cd scrcpy && meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=/scrcpy-server.jar
RUN cd scrcpy/x && ninja

### runner
FROM alpine:edge AS runner

# needed for android-tools
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

LABEL maintainer="Pierre Gordon <pierregordon@protonmail.com>"

RUN apk add --no-cache \
        android-tools \
        ffmpeg \
        virtualgl

COPY --from=builder /scrcpy-server.jar /usr/local/share/scrcpy/
COPY --from=builder /scrcpy/x/app/scrcpy /usr/local/bin/

### runner (amd)
FROM runner AS amd

RUN apk add --no-cache mesa-dri-swrast

### runner (intel)
FROM runner AS intel

RUN apk add --no-cache mesa-dri-intel

### runner (nvidia)
FROM runner AS nvidia

RUN apk add --no-cache mesa-dri-nouveau
