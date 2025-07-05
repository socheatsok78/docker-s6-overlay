# The S6_VERSION variable is used to specify the version of s6-overlay to build.
# It MUST NOT provides any default value.
# It is expected to be set by the user or CI when running the build command.
#
# e.g: S6_VERSION=v3.2.0.0 docker buildx bake build
ARG S6_VERSION

ARG S6_REPO=just-containers/s6-overlay
ARG S6_DOWNLOAD_URL=https://github.com/${S6_REPO}/releases/download/${S6_VERSION}
ARG ALPINE_VERSION=3.22.0

# Download s6-overlay tarballs and verify their checksums.
# $ docker buildx bake download --no-cache
# 
# Or maunally run each target:
# $ docker buildx bake tarballs --no-cache
FROM scratch AS tarballs
ARG S6_DOWNLOAD_URL
ADD ${S6_DOWNLOAD_URL}/s6-overlay-noarch.tar.xz                     /s6-overlay-noarch.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-aarch64.tar.xz                    /s6-overlay-aarch64.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-arm.tar.xz                        /s6-overlay-arm.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-armhf.tar.xz                      /s6-overlay-armhf.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-i686.tar.xz                       /s6-overlay-i686.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-riscv64.tar.xz                    /s6-overlay-riscv64.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-s390x.tar.xz                      /s6-overlay-s390x.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-x86_64.tar.xz                     /s6-overlay-x86_64.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-symlinks-arch.tar.xz              /s6-overlay-symlinks-arch.tar.xz
ADD ${S6_DOWNLOAD_URL}/s6-overlay-symlinks-noarch.tar.xz            /s6-overlay-symlinks-noarch.tar.xz
ADD ${S6_DOWNLOAD_URL}/syslogd-overlay-noarch.tar.xz                /syslogd-overlay-noarch.tar.xz
# 
# $ docker buildx bake verify --no-cache
ADD ${S6_DOWNLOAD_URL}/s6-overlay-noarch.tar.xz.sha256              /s6-overlay-noarch.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-aarch64.tar.xz.sha256             /s6-overlay-aarch64.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-arm.tar.xz.sha256                 /s6-overlay-arm.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-armhf.tar.xz.sha256               /s6-overlay-armhf.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-i686.tar.xz.sha256                /s6-overlay-i686.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-riscv64.tar.xz.sha256             /s6-overlay-riscv64.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-s390x.tar.xz.sha256               /s6-overlay-s390x.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-x86_64.tar.xz.sha256              /s6-overlay-x86_64.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-symlinks-arch.tar.xz.sha256       /s6-overlay-symlinks-arch.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/s6-overlay-symlinks-noarch.tar.xz.sha256     /s6-overlay-symlinks-noarch.tar.xz.sha256
ADD ${S6_DOWNLOAD_URL}/syslogd-overlay-noarch.tar.xz.sha256         /syslogd-overlay-noarch.tar.xz.sha256

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS verify
WORKDIR /tmp/output
RUN --mount=type=bind,from=tarballs,source=/,target=/tmp/output sha256sum -cw *.sha256

# Specify the target architecture and variant for s6-overlay

# | ${TARGETARCH} | ${arch} | Notes                 |
# |:--------------|:--------|:----------------------|
# | 386           | i686    | i486 for very old hw  |
# | amd64         | x86_64  |                       |
# | armv6         | armhf   | Raspberry Pi 1        |
# | armv7         | arm     | armv7 with soft-float |
# | arm64         | aarch64 |                       |
# | riscv64       | riscv64 |                       |
# | s390x         | s390x   |                       |

# See https://github.com/just-containers/s6-overlay/blob/d6f37bb2052cfc5705154315419dcacb3975f11e/README.md?plain=1#L1023

# s6-overlay-noarch.tar.xz
FROM scratch AS s6-overlay-noarch
ADD output/s6-overlay-noarch.tar.xz /

# s6-overlay-i686.tar.xz
FROM s6-overlay-noarch AS s6-overlay-386
ADD output/s6-overlay-i686.tar.xz /

# s6-overlay-x86_64.tar.xz
FROM s6-overlay-noarch AS s6-overlay-amd64
ADD output/s6-overlay-x86_64.tar.xz /

# s6-overlay-armhf.tar.xz
FROM s6-overlay-noarch AS s6-overlay-armv6
ADD output/s6-overlay-armhf.tar.xz /

# s6-overlay-arm.tar.xz
FROM s6-overlay-noarch AS s6-overlay-armv7
ADD output/s6-overlay-arm.tar.xz /

# s6-overlay-aarch64.tar.xz
FROM s6-overlay-noarch AS s6-overlay-arm64
ADD output/s6-overlay-aarch64.tar.xz /

# s6-overlay-riscv64.tar.xz
FROM s6-overlay-noarch AS s6-overlay-riscv64
ADD output/s6-overlay-riscv64.tar.xz /

# s6-overlay-s390x.tar.xz
FROM s6-overlay-noarch AS s6-overlay-s390x
ADD output/s6-overlay-s390x.tar.xz /

# s6-overlay
# This is the default target for s6-overlay, the architecture and variant will be determined by the build platform
FROM s6-overlay-${TARGETARCH}${TARGETVARIANT} AS s6-overlay
FROM s6-overlay


# s6-overlay-symlinks-noarch.tar.xz & s6-overlay-symlinks-arch.tar.xz
FROM scratch AS s6-overlay-symlinks
ADD output/s6-overlay-symlinks-noarch.tar.xz /
ADD output/s6-overlay-symlinks-arch.tar.xz /


# syslogd-overlay-noarch.tar.xz
FROM scratch AS s6-overlay-syslogd
ADD output/syslogd-overlay-noarch.tar.xz /
